import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  /// Dicoba berurutan. Prioritas: aset GitHub Release (selalu sepasang dengan APK
  /// terbaru), lalu Firebase Hosting sebagai cadangan.
  static const List<String> _metaUrls = [
    'https://github.com/ridlofw/motorqu/releases/latest/download/latest.json',
    'https://motorqu-e81dd.web.app/appMeta/latest.json',
  ];
  static const String _apkUrl =
      'https://github.com/ridlofw/motorqu/releases/latest/download/app-release.apk';

  /// Ambil metadata versi terbaru (GitHub Release / Firebase Hosting).
  /// Mengembalikan Map JSON atau null jika gagal/offline.
  Future<Map<String, dynamic>?> checkForUpdate() async {
    for (final url in _metaUrls) {
      try {
        final resp = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 10),
            );
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {
        // Coba sumber berikutnya.
      }
    }
    return null;
  }

  /// Bandingkan versionCode server dengan buildNumber APK terpasang.
  Future<bool> hasUpdate(Map<String, dynamic> meta) async {
    final info = await PackageInfo.fromPlatform();
    final serverCode = int.tryParse(meta['versionCode'].toString()) ?? 0;
    final localCode = int.tryParse(info.buildNumber) ?? 0;
    return serverCode > localCode;
  }

  /// Unduh APK dengan kemampuan resume (HTTP Range 206) dan retry otomatis
  /// jika koneksi terputus di tengah jalan, lalu buka installer sistem Android.
  Future<String?> downloadAndInstall({
    String? targetVersionCode,
    void Function(int received, int total, String status)? onProgress,
  }) async {
    final dir = await _downloadDir();
    if (!dir.existsSync()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {}
    }

    // Beri nama spesifik versi agar tidak bentrok dengan sisa versi lama
    final filename = targetVersionCode != null
        ? 'motorqu_update_$targetVersionCode.apk'
        : 'motorqu_update.apk';
    final target = File('${dir.path}/$filename');

    // Bersihkan file update versi lain yang sudah tidak dipakai
    try {
      for (final entity in dir.listSync()) {
        if (entity is File &&
            entity.path.contains('motorqu_update') &&
            entity.path != target.path) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}

    int totalBytes = 0;
    const int maxRetries = 8;
    String? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      int downloaded = 0;
      if (target.existsSync()) {
        downloaded = target.lengthSync();
      }

      // Jika file sudah terunduh lengkap sebelumnya
      if (totalBytes > 0 && downloaded >= totalBytes) {
        lastError = null;
        break;
      }

      final client = http.Client();
      IOSink? sink;

      try {
        final request = http.Request('GET', Uri.parse(_apkUrl));
        request.headers['Connection'] = 'keep-alive';
        request.headers['User-Agent'] = 'MotorQu-Android-App';

        if (downloaded > 0) {
          // Lanjutkan download dari byte yang sudah berhasil disimpan
          request.headers['Range'] = 'bytes=$downloaded-';
          if (onProgress != null) {
            final dlMb = (downloaded / (1024 * 1024)).toStringAsFixed(1);
            onProgress(
              downloaded,
              totalBytes,
              'Melanjutkan unduhan ($dlMb MB tersimpan)...',
            );
          }
        } else {
          if (onProgress != null) {
            onProgress(0, totalBytes, 'Menghubungkan ke server...');
          }
        }

        final streamed = await client.send(request).timeout(
              const Duration(seconds: 45),
            );

        if (streamed.statusCode == 206) {
          // Server mendukung resume partial content
          final cr = streamed.headers['content-range'];
          if (cr != null && cr.contains('/')) {
            final totalStr = cr.split('/').last.trim();
            totalBytes = int.tryParse(totalStr) ?? totalBytes;
          } else if (streamed.contentLength != null) {
            totalBytes = downloaded + streamed.contentLength!;
          }
          sink = target.openWrite(mode: FileMode.append);
        } else if (streamed.statusCode == 200) {
          // Download dari awal
          downloaded = 0;
          totalBytes = streamed.contentLength ?? 0;
          sink = target.openWrite(mode: FileMode.write);
        } else if (streamed.statusCode == 416) {
          // Range not satisfiable
          if (target.existsSync() && target.lengthSync() > 10000000) {
            lastError = null;
            break;
          } else {
            try {
              target.deleteSync();
            } catch (_) {}
            continue;
          }
        } else {
          lastError = 'Server HTTP ${streamed.statusCode}';
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        int received = downloaded;
        await for (final chunk in streamed.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (onProgress != null) {
            final p = totalBytes > 0 ? (received / totalBytes) : 0.0;
            final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
            final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            final pct = (p * 100).toInt();
            onProgress(
              received,
              totalBytes,
              '$recMb MB / $totMb MB ($pct%)',
            );
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;

        // Verifikasi kelengkapan ukuran
        final finalLen = target.existsSync() ? target.lengthSync() : 0;
        if (totalBytes > 0 && finalLen >= totalBytes) {
          lastError = null;
          break; // Sukses terunduh penuh!
        }
      } catch (e) {
        lastError = e.toString();
        // Beri jeda 2 detik sebelum mencoba menyambung kembali
        await Future.delayed(const Duration(seconds: 2));
      } finally {
        if (sink != null) {
          try {
            await sink.close();
          } catch (_) {}
        }
        client.close();
      }
    }

    if (lastError != null &&
        (!target.existsSync() ||
            (totalBytes > 0 && target.lengthSync() < totalBytes))) {
      return 'Gagal mengunduh: $lastError';
    }

    if (!target.existsSync() || target.lengthSync() < 1000) {
      return 'File APK tidak lengkap saat diunduh.';
    }

    // Buka installer sistem Android via open_filex
    // Menggunakan getExternalStorageDirectory() memastikan file berada di
    // getExternalFilesDir(null) yang diizinkan tanpa MANAGE_EXTERNAL_STORAGE.
    final result = await OpenFilex.open(
      target.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      return result.message;
    }
    return null; // Sukses membuka installer
  }

  /// Lokasi direktori penyimpanan APK update.
  /// WAJIB menggunakan getExternalStorageDirectory() (context.getExternalFilesDir(null))
  /// agar open_filex TIDAK meminta izin android.Manifest.permission.MANAGE_EXTERNAL_STORAGE.
  Future<Directory> _downloadDir() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        return ext;
      }
    } catch (_) {}
    try {
      return await getApplicationSupportDirectory();
    } catch (_) {}
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {}
    return Directory.systemTemp;
  }
}
