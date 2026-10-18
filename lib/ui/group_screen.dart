import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../services/database_service.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final DatabaseService _db = DatabaseService();
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  FamilyGroup? _group;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final g = await _db.getUserGroup(_myUid);
    List<Map<String, dynamic>> m = [];
    if (g != null) {
      m = await _db.getGroupMembers(g);
    }
    if (mounted) {
      setState(() {
        _group = g;
        _members = m;
        _loading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Grup Keluarga'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Grup',
            hintText: 'Keluarga Ridlo',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    try {
      await _db.createGroup(name);
      _toast('Grup berhasil dibuat');
      _refresh();
    } catch (e) {
      _toast('Gagal buat grup: $e');
    }
  }

  Future<void> _joinGroup() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masuk Grup'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Kode Undangan (6 Huruf/Angka)',
            hintText: 'ABC123',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().toUpperCase()),
            child: const Text('Gabung'),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty) return;
    try {
      await _db.joinGroupWithCode(code);
      _toast('Berhasil bergabung ke grup');
      _refresh();
    } catch (e) {
      _toast('Gagal gabung: $e');
    }
  }

  Future<void> _generateInvite() async {
    if (_group == null) return;
    try {
      final code = await _db.createInviteCode(_group!.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kode Undangan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bagikan kode 6 karakter ini ke anggota keluarga Anda. '
                  'Kode berlaku selama 7 hari dan hanya bisa dipakai sekali.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.pop(ctx);
                  _toast('Kode berhasil disalin');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Salin'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _toast('Gagal membuat kode: $e');
    }
  }

  Future<void> _leaveGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Grup'),
        content: const Text(
          'Motor milik Anda yang dibagikan ke grup ini tidak akan bisa '
          'diakses lagi oleh anggota lain.',
        ),
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
    if (ok != true || _group == null) return;
    try {
      await _db.leaveGroup(_group!.id);
      _toast('Anda telah keluar dari grup');
      _refresh();
    } catch (e) {
      _toast('Gagal keluar: $e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Grup Keluarga')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _group == null
              ? _noGroupView()
              : _groupView(),
    );
  }

  Widget _noGroupView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum Tergabung dalam Grup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat grup baru atau minta kode undangan dari keluarga Anda '
              'untuk berbagi data motor dan riwayat oli.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createGroup,
              icon: const Icon(Icons.add),
              label: const Text('Buat Grup Baru'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _joinGroup,
              icon: const Icon(Icons.login),
              label: const Text('Gabung Pakai Kode'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupView() {
    final g = _group!;
    final isOwner = g.ownerId == _myUid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 32, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isOwner ? 'Anda adalah Pemilik Grup' : 'Anggota',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isOwner)
                  FilledButton.icon(
                    onPressed: _generateInvite,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Buat Kode Undangan'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Anggota Grup',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._members.map((m) {
          final isMe = m['uid'] == _myUid;
          final isGroupOwner = m['uid'] == g.ownerId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  m['photoUrl'] != null ? NetworkImage(m['photoUrl']) : null,
              child: m['photoUrl'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              m['displayName'] ?? 'Pengguna',
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(m['email'] ?? ''),
            trailing: isGroupOwner
                ? const Chip(label: Text('Owner', style: TextStyle(fontSize: 11)))
                : null,
          );
        }),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: _leaveGroup,
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          label: const Text(
            'Keluar dari Grup',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }
}