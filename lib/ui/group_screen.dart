import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../models/motorcycle.dart';
import '../services/database_service.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final DatabaseService _db = DatabaseService();
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  String? _selectedGroupId;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            hintText: 'contoh: Keluarga Ridlo, Motor Mertua',
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
      final newId = await _db.createGroup(name);
      setState(() => _selectedGroupId = newId);
      _toast('Grup "$name" berhasil dibuat');
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
            labelText: 'Kode Undangan (6 Karakter)',
            hintText: 'contoh: ABC123',
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
      final newGroupId = await _db.joinGroupWithCode(code);
      setState(() => _selectedGroupId = newGroupId);
      _toast('Berhasil bergabung ke grup');
    } catch (e) {
      _toast('Gagal gabung: $e');
    }
  }

  Future<void> _editGroupName(FamilyGroup group) async {
    final ctrl = TextEditingController(text: group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Grup'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Grup',
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == group.name) return;
    try {
      await _db.updateGroupName(group.id, newName);
      _toast('Nama grup diperbarui');
    } catch (e) {
      _toast('Gagal ubah nama: $e');
    }
  }

  Future<void> _generateInvite(FamilyGroup group) async {
    try {
      final code = await _db.createInviteCode(group.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kode Undangan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bagikan kode 6 karakter ini ke anggota grup "${group.name}". '
                'Kode berlaku 7 hari dan hanya bisa dipakai sekali.',
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
    } catch (e) {
      _toast('Gagal membuat kode: $e');
    }
  }

  Future<void> _addMotorToGroupDialog(FamilyGroup group) async {
    try {
      final myPrivates = await _db.getUserPrivateMotorcycles(_myUid);
      if (!mounted) return;

      if (myPrivates.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tidak Ada Motor Pribadi'),
            content: const Text(
              'Semua motor Anda sudah masuk grup, atau Anda belum menambahkan motor.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pilih Motor untuk Masuk ke "${group.name}"',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...myPrivates.map((m) {
                return ListTile(
                  leading: const Icon(Icons.two_wheeler, color: Colors.blue),
                  title: Text(m.name),
                  subtitle: Text('${m.brand} ${m.model} ${m.plate ?? ''}'),
                  trailing: const Icon(Icons.add_circle, color: Colors.green),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await _db.assignMotorcycleToGroup(m.id, group.id);
                      _toast('Motor "${m.name}" berhasil dimasukkan ke grup');
                    } catch (e) {
                      _toast('Gagal memasukkan motor: $e');
                    }
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    } catch (e) {
      _toast('Gagal memuat motor pribadi: $e');
    }
  }

  Future<void> _removeMotorFromGroup(Motorcycle moto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan Motor dari Grup?'),
        content: const Text(
          'kamu yakin akan menghapus motor ini dari grup, motor yang kamu hapus dari grup ini nanti akan menjadi motor individu dari pemilik yang menambahkannya.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _db.removeMotorcycleFromGroup(moto.id, moto.createdBy);
      _toast('Motor "${moto.name}" telah dikeluarkan ke motor pribadi');
    } catch (e) {
      _toast('Gagal mengeluarkan motor: $e');
    }
  }

  Future<void> _leaveGroup(FamilyGroup group) async {
    final isOwner = group.isOwner(_myUid);
    final isCreator = group.ownerId == _myUid;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCreator
            ? 'Hapus/Tinggalkan Grup'
            : (isOwner ? 'Keluar dari Grup (Owner)' : 'Keluar dari Grup')),
        content: Text(
          isCreator
              ? 'Anda adalah pembuat utama grup "${group.name}". Jika Anda keluar, '
                  'kepemilikan akan dialihkan atau grup akan ditutup jika tidak ada anggota lain.'
              : (isOwner
                  ? 'Anda adalah salah satu owner di grup "${group.name}". Jika keluar, status owner Anda akan dilepas dan motor Anda otomatis ditarik kembali ke motor pribadi.'
                  : 'Motor milik Anda yang dibagikan ke grup "${group.name}" akan otomatis '
                      'ditarik kembali menjadi motor pribadi Anda.'),
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

    if (ok != true) return;
    try {
      await _db.leaveGroup(group.id);
      _toast('Anda telah keluar dari grup "${group.name}"');
      setState(() => _selectedGroupId = null);
    } catch (e) {
      _toast('Gagal keluar: $e');
    }
  }

  Future<void> _kickMember(FamilyGroup group, Map<String, dynamic> member) async {
    final memberName = member['displayName'] ?? 'Anggota';
    final targetUid = member['uid'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Keluarkan Anggota?'),
          ],
        ),
        content: Text(
          'Yakin ingin mengeluarkan "$memberName" dari grup "${group.name}"?\n\n'
          'Motor milik "$memberName" yang ada di dalam grup ini akan otomatis ditarik kembali menjadi motor pribadinya.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.kickMember(group.id, targetUid);
      _toast('"$memberName" telah dikeluarkan dari grup');
      setState(() {});
    } catch (e) {
      _toast('Gagal mengeluarkan anggota: $e');
    }
  }

  Future<void> _promoteMemberToOwner(FamilyGroup group, Map<String, dynamic> member) async {
    final memberName = member['displayName'] ?? 'Anggota';
    final targetUid = member['uid'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.military_tech_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Jadikan Owner / Admin?'),
          ],
        ),
        content: Text(
          'Angkat "$memberName" sebagai Owner / Admin grup "${group.name}"?\n\n'
          'Grup ini bisa memiliki banyak owner seperti grup WhatsApp. "$memberName" akan memiliki hak untuk mengelola motor dan anggota grup.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Jadikan Owner'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.promoteMemberToOwner(group.id, targetUid);
      _toast('"$memberName" sekarang menjadi Owner grup');
      setState(() {});
    } catch (e) {
      _toast('Gagal mengangkat owner: $e');
    }
  }

  Future<void> _demoteOwner(FamilyGroup group, Map<String, dynamic> member) async {
    final memberName = member['displayName'] ?? 'Anggota';
    final targetUid = member['uid'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.remove_moderator_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Turunkan Status Owner?'),
          ],
        ),
        content: Text(
          'Turunkan "$memberName" menjadi anggota biasa di grup "${group.name}"?',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Turunkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.demoteOwner(group.id, targetUid);
      _toast('Status owner "$memberName" telah dicabut');
      setState(() {});
    } catch (e) {
      _toast('Gagal mencabut status owner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Grup Keluarga'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'create') _createGroup();
              if (val == 'join') _joinGroup();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.group_add, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Buat Grup Baru'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'join',
                child: Row(
                  children: [
                    Icon(Icons.login, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Gabung Pakai Kode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<FamilyGroup>>(
        stream: _db.getUserGroups(_myUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return _noGroupView();
          }

          if (_selectedGroupId == null || !groups.any((g) => g.id == _selectedGroupId)) {
            _selectedGroupId = groups.first.id;
          }

          final activeGroup = groups.firstWhere(
            (g) => g.id == _selectedGroupId,
            orElse: () => groups.first,
          );

          return _groupDetailView(groups, activeGroup);
        },
      ),
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
              'Anda bisa membuat banyak grup (keluarga kandung, mertua, atau komunitas) '
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

  Widget _groupDetailView(List<FamilyGroup> allGroups, FamilyGroup activeGroup) {
    final isOwner = activeGroup.isOwner(_myUid);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pemilih grup jika user punya lebih dari 1 grup
        if (allGroups.length > 1) ...[
          Card(
            color: Colors.blue.withValues(alpha: 0.05),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.switch_account, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text(
                    'Grup:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeGroup.id,
                        isExpanded: true,
                        items: allGroups.map((g) {
                          return DropdownMenuItem<String>(
                            value: g.id,
                            child: Text(
                              g.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) setState(() => _selectedGroupId = id);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Kartu Utama Info Grup
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.group, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  activeGroup.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                tooltip: 'Ubah Nama Grup',
                                onPressed: () => _editGroupName(activeGroup),
                              ),
                            ],
                          ),
                          Text(
                            isOwner ? 'Anda adalah Owner/Admin Grup' : 'Anggota Grup',
                            style: TextStyle(
                              fontSize: 13,
                              color: isOwner ? Colors.blue : Colors.grey[700],
                              fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _generateInvite(activeGroup),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Undang Anggota'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // SECTION: KELOLA MOTOR DI GRUP INI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Motor di Grup Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _addMotorToGroupDialog(activeGroup),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Motor'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Motorcycle>>(
          stream: _db.getGroupMotorcycles(activeGroup.id),
          builder: (context, motoSnap) {
            if (motoSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
            }
            final groupMotos = motoSnap.data ?? [];
            if (groupMotos.isEmpty) {
              return Card(
                color: Colors.grey.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.two_wheeler, color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum ada motor yang dibagikan ke grup ini.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _addMotorToGroupDialog(activeGroup),
                        child: const Text('Masukkan Motor Pribadi ke Sini'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: groupMotos.map((m) {
                final isMyMotor = m.createdBy == _myUid;
                final canRemoveMotor = isMyMotor || isOwner;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.two_wheeler),
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${m.brand} ${m.model} ${m.plate != null ? "• ${m.plate}" : ""}\n'
                      'Oli terakhir: ${m.lastOdometer} KM · Target: ${m.nextDueKm} KM',
                    ),
                    isThreeLine: true,
                    trailing: canRemoveMotor
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                            tooltip: isMyMotor
                                ? 'Keluarkan Motor Saya dari Grup'
                                : 'Keluarkan Motor Ini dari Grup',
                            onPressed: () => _removeMotorFromGroup(m),
                          )
                        : const Chip(
                            label: Text('Grup', style: TextStyle(fontSize: 10)),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // SECTION: ANGGOTA GRUP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Anggota (${activeGroup.memberUids.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _db.getGroupMembers(activeGroup),
          builder: (context, memberSnap) {
            if (memberSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
            }
            final members = memberSnap.data ?? [];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final m = members[index];
                  final isMe = m['uid'] == _myUid;
                  final isMemberOwner = activeGroup.isOwner(m['uid']);
                  final isGroupCreator = m['uid'] == activeGroup.ownerId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: m['photoUrl'] != null &&
                              (m['photoUrl'] as String).trim().isNotEmpty
                          ? NetworkImage(m['photoUrl'])
                          : null,
                      child: m['photoUrl'] == null ||
                              (m['photoUrl'] as String).trim().isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      m['displayName'] ?? 'Pengguna',
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(m['email'] ?? ''),
                    trailing: isMe
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMemberOwner)
                                Chip(
                                  label: Text(
                                    isGroupCreator ? 'Owner Utama' : 'Owner',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: isGroupCreator
                                      ? Colors.amber.shade100
                                      : Colors.blue.shade50,
                                ),
                              const SizedBox(width: 4),
                              const Chip(
                                label: Text('Anda', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMemberOwner)
                                Chip(
                                  label: Text(
                                    isGroupCreator ? 'Owner Utama' : 'Owner',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: isGroupCreator
                                      ? Colors.amber.shade100
                                      : Colors.blue.shade50,
                                ),
                              if (isOwner)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  tooltip: 'Kelola Anggota',
                                  onSelected: (val) {
                                    if (val == 'promote') {
                                      _promoteMemberToOwner(activeGroup, m);
                                    } else if (val == 'demote') {
                                      _demoteOwner(activeGroup, m);
                                    } else if (val == 'kick') {
                                      _kickMember(activeGroup, m);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    if (!isMemberOwner)
                                      const PopupMenuItem(
                                        value: 'promote',
                                        child: Row(
                                          children: [
                                            Icon(Icons.military_tech_rounded,
                                                color: Colors.blue, size: 20),
                                            SizedBox(width: 8),
                                            Text('Jadikan Owner / Admin'),
                                          ],
                                        ),
                                      )
                                    else if (!isGroupCreator)
                                      const PopupMenuItem(
                                        value: 'demote',
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove_moderator_rounded,
                                                color: Colors.orange, size: 20),
                                            SizedBox(width: 8),
                                            Text('Turunkan dari Owner'),
                                          ],
                                        ),
                                      ),
                                    if (!isGroupCreator)
                                      const PopupMenuItem(
                                        value: 'kick',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_remove_rounded,
                                                color: Colors.red, size: 20),
                                            SizedBox(width: 8),
                                            Text('Keluarkan dari Grup',
                                                style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Tombol Keluar Grup
        OutlinedButton.icon(
          onPressed: () => _leaveGroup(activeGroup),
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          label: Text(
            isOwner ? 'Tinggalkan / Keluar dari Grup' : 'Keluar dari Grup',
            style: const TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
