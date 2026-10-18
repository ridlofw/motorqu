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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Versi Baru Tersedia'),
        content: Text(
          'Versi ${meta['versionName'] ?? meta['versionCode']} siap diunduh. '
          'Install APK baru sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unduh'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    try {
      final ok = await _update.downloadAndInstall();
      if (!mounted) return;
      _toast(ok ? 'Installer dibuka' : 'Gagal menginstal');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal: $e');
    }
  }

  Future<void> _toggleNotif(bool val) async {
    final prefs = await SharedPreferences.getInstance();
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
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Pengingat Ganti Oli'),
                subtitle: const Text('Notifikasi berkala 30 hari'),
                value: _notifEnabled,
                onChanged: _toggleNotif,
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