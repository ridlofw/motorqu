import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:convert';

class UpdateService {
  static const String _metaUrl =
      'https://motorqu-e81dd.web.app/appMeta/latest.json';
  static const String _apkUrl =
      'https://github.com/ridlofw/motorqu/releases/latest/download/app-release.apk';

  /// Ambil metadata versi terbaru dari Firebase Hosting.
  /// Mengembalikan Map JSON atau null jika gagal/offline.
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final resp = await http.get(Uri.parse(_metaUrl)).timeout(
            const Duration(seconds: 10),
          );
      if (resp.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(resp.body) as Map);
      }
    } catch (_) {
      // Offline / hosting belum aktif -> anggap tidak ada update.
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

  /// Unduh APK ke file sementara lalu buka installer-nya.
  Future<bool> downloadAndInstall() async {
    final dir = await _downloadDir();
    final target = File('${dir.path}/motorqu_update.apk');
    if (target.existsSync()) await target.delete();

    final request = http.Request('GET', Uri.parse(_apkUrl));
    final client = http.Client();
    try {
      final streamed = await client.send(request);
      if (streamed.statusCode != 200) return false;
      final sink = target.openWrite();
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
      }
      await sink.close();
    } finally {
      client.close();
    }

    final result = await OpenFilex.open(target.path, type: 'application/vnd.android.package-archive');
    return result.type == ResultType.done;
  }

  Future<Directory> _downloadDir() async {
    // documents directory via path_provider
    // ignore: avoid_slow_async_io
    return Directory.systemTemp;
  }
}
