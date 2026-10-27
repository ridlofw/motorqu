import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../models/group.dart';
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
  String _version = '1.0.6';
  String _buildNumber = '7';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      if (mounted) {
        setState(() => _notifEnabled = enabled);
        _notif.setEnabled(enabled);
      }
    } catch (_) {}

    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
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
      _toast('Aplikasi Anda sudah versi terbaru (v$_version).');
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

    double progress = 0.0;
    String statusText = 'Menghubungkan...';
    void Function(void Function())? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) {
          dialogSetState = setDlgState;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Mengunduh Pembaruan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 8,
                    ),
                  ),
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
        targetVersionCode: meta['versionCode']?.toString(),
        onProgress: (received, total, status) {
          progress = total > 0 ? (received / total) : 0.0;
          statusText = status;
          if (dialogSetState != null) {
            dialogSetState!(() {});
          }
        },
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog
      if (errorMsg != null) {
        _toast('Gagal mengunduh: $errorMsg');
      } else {
        _toast('Installer dibuka. Silakan tekan Install.');
      }
    }
  }

  Future<void> _toggleNotif(bool val) async {
    setState(() => _notifEnabled = val);
    _notif.setEnabled(val);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', val);
    } catch (_) {}

    if (val) {
      try {
        final granted = await _notif.requestPermission();
        if (!granted && mounted) {
          _toast('Izin notifikasi belum diaktifkan di HP.');
        }
      } catch (_) {}
      _toast('Pengingat ganti oli aktif');
    } else {
      try {
        await _notif.cancelAll();
      } catch (_) {}
      _toast('Pengingat dinonaktifkan');
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
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _notif.showTestNotification();
              _toast('Notifikasi uji coba dikirim! Periksa panel notifikasi HP.');
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim Notifikasi Tes'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Yakin ingin keluar dari akun Google ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil & Setelan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _db.getUserProfile(uid),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final name = data?['displayName'] ?? user?.displayName ?? 'Pengguna MotorQu';
          final email = data?['email'] ?? user?.email ?? '';
          final photo = data?['photoUrl'] ?? user?.photoURL;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // 1. Profil Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.indigo.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null
                          ? const Icon(Icons.person, size: 36, color: Colors.blue)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Akun Google Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION: GRUP KELUARGA
              _buildSectionTitle('Grup Keluarga'),
              StreamBuilder<List<FamilyGroup>>(
                stream: _db.getUserGroups(uid),
                builder: (context, groupSnap) {
                  final groupCount = (groupSnap.data ?? []).length;
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.group_rounded, color: Colors.blue),
                      ),
                      title: const Text(
                        'Kelola Grup Keluarga',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        groupCount > 0
                            ? '$groupCount grup diikuti • Edit nama & kelola motor'
                            : 'Belum bergabung ke grup keluarga',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GroupScreen()),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // SECTION: NOTIFIKASI
              _buildSectionTitle('Pengingat & Notifikasi'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _notifEnabled ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _notifEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: _notifEnabled ? Colors.green.shade700 : Colors.grey,
                        ),
                      ),
                      title: const Text(
                        'Pengingat Ganti Oli',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        _notifEnabled
                            ? 'Aktif (berkala setiap 30 hari)'
                            : 'Nonaktif (tidak akan menerima alarm oli)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _notifEnabled,
                      onChanged: _toggleNotif,
                    ),
                    const Divider(height: 1, indent: 64),
                    ListTile(
                      dense: true,
                      leading: const SizedBox(width: 32),
                      title: const Text(
                        'Informasi & Tes Notifikasi',
                        style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                      onTap: _showReminderInfo,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION: PEMBARUAN & APLIKASI
              _buildSectionTitle('Sistem & Pembaruan'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.system_update_rounded, color: Colors.orange),
                  ),
                  title: const Text(
                    'Versi Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    'v$_version (Build $_buildNumber)',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  trailing: FilledButton.tonalIcon(
                    onPressed: _checkUpdate,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Cek Update', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // SECTION: KELUAR
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
