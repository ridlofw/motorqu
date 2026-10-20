import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import 'group_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();
  final UpdateService _update = UpdateService();

  bool _notifEnabled = true;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _notifEnabled = prefs.getBool('notifications_enabled') ?? true;
        _version = '${info.version}+${info.buildNumber}';
      });
      _notif.setEnabled(_notifEnabled);
    }
  }

  Future<void> _checkUpdate() async {
    final meta = await _update.checkForUpdate();
    if (!mounted) return;
    if (meta == null) {
      _toast('Tidak dapat menghubungkan ke server update.');
      return;
    }
    final newer = await _update.hasUpdate(meta);
    if (!newer) {
      _toast('Aplikasi Anda sudah versi terbaru.');
      return;
    }
    final targetVer = meta['versionName'] ?? meta['versionCode'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Versi Baru Tersedia'),
        content: Text(
          'Versi v$targetVer siap diunduh. '
          'Install APK baru sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unduh & Install'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Tampilkan dialog progress unduh
    double progress = 0.0;
    String statusText = 'Menghubungkan...';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Mengunduh Pembaruan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress > 0 ? progress : null),
                  const SizedBox(height: 12),
                  Text(statusText, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );

    String? errorMsg;
    try {
      errorMsg = await _update.downloadAndInstall(
        onProgress: (received, total) {
          if (total > 0) {
            final p = received / total;
            final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
            final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
            // update state dialog jika masih ada
            progress = p;
            statusText = '$recMb MB / $totMb MB (${(p * 100).toInt()}%)';
          }
        },
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog download
      if (errorMsg != null) {
        _toast('Gagal mengunduh update: $errorMsg');
      } else {
        _toast('Installer dibuka. Silakan tekan Install.');
      }
    }
  }

  Future<void> _toggleNotif(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val) {
      final granted = await _notif.requestPermission();
      if (!granted) {
        _toast('Izin notifikasi ditolak di pengaturan HP.');
      }
    }
    await prefs.setBool('notifications_enabled', val);
    setState(() => _notifEnabled = val);
    _notif.setEnabled(val);
    if (!val) {
      await _notif.cancelAll();
      _toast('Semua pengingat dinonaktifkan');
    } else {
      _toast('Pengingat aktif');
    }
  }

  Future<void> _showReminderInfo() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.blue),
            SizedBox(width: 8),
            Text('Pengingat Ganti Oli'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengingat ganti oli akan otomatis berbunyi setiap 30 hari sekali '
              'sejak terakhir kali Anda mencatat ganti oli motor.\n\n'
              'Wording pengingat:\n'
              '"Jika KM motor <nama> sudah lebih dari <target> KM, jangan lupa ganti oli yaa"\n\n'
              'Ketika notifikasi ditekan, aplikasi akan langsung membuka halaman Catat Oli dengan motor yang dipilih secara otomatis.',
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _notif.showTestNotification();
              _toast('Notifikasi uji coba dikirim! Periksa panel notifikasi HP Anda.');
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim Notifikasi Tes'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return StreamBuilder<Map<String, dynamic>?>(
        stream: _db.getUserProfile(uid),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final name = data?['displayName'] ?? user?.displayName ?? 'Pengguna';
          final email = data?['email'] ?? user?.email ?? '';
          final photo = data?['photoUrl'] ?? user?.photoURL;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Kelola Grup Keluarga'),
                subtitle: const Text('Lihat anggota, buat kode undangan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroupScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Pengingat Ganti Oli'),
                subtitle: Text(
                  _notifEnabled
                      ? 'Aktif (tiap 30 hari). Ketuk untuk info & tes.'
                      : 'Nonaktif. Ketuk untuk mengaktifkan.',
                ),
                trailing: Switch(
                  value: _notifEnabled,
                  onChanged: _toggleNotif,
                ),
                onTap: _showReminderInfo,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('Versi Aplikasi'),
                subtitle: Text('v$_version'),
                trailing: TextButton(
                  onPressed: _checkUpdate,
                  child: const Text('Cek Update'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
    );
  }
}