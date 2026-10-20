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

  /// Unduh APK dengan callback progres lalu buka installer sistem Android.
  Future<String?> downloadAndInstall({
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _downloadDir();
    final target = File('${dir.path}/motorqu_update.apk');
    if (target.existsSync()) {
      try {
        await target.delete();
      } catch (_) {}
    }

    final request = http.Request('GET', Uri.parse(_apkUrl));
    final client = http.Client();
    try {
      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        return 'Gagal mengunduh APK (Server HTTP ${streamed.statusCode})';
      }
      final sink = target.openWrite();
      int received = 0;
      final total = streamed.contentLength ?? 0;

      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null) {
          onProgress(received, total);
        }
      }
      await sink.close();
    } finally {
      client.close();
    }

    if (!target.existsSync() || target.lengthSync() < 1000) {
      return 'File APK tidak lengkap atau rusak saat diunduh.';
    }

    final result = await OpenFilex.open(
      target.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      return result.message;
    }
    return null; // Sukses membuka installer
  }

  Future<Directory> _downloadDir() async {
    try {
      final ext = await getExternalCacheDirectories();
      if (ext != null && ext.isNotEmpty) {
        return ext.first;
      }
    } catch (_) {}
    try {
      return await getTemporaryDirectory();
    } catch (_) {}
    return Directory.systemTemp;
  }
}
