import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/motorcycle.dart';
import 'motor_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final NotificationService notificationService;
  const HomeScreen({super.key, required this.notificationService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  int _index = 0; // 0 = Motor, 1 = Profil
  String _filter = 'all'; // 'all', 'private', 'group'

  void _openActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aksi Cepat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih tindakan yang ingin langsung kamu lakukan',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.build_circle_rounded,
                      color: Colors.amber.shade800,
                      bgColor: Colors.amber.shade50,
                      title: 'Catat Oli',
                      subtitle: 'Update KM & riwayat oli',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/addOil');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.two_wheeler_rounded,
                      color: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                      title: 'Tambah Motor',
                      subtitle: 'Daftarkan motor baru',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/addMotor');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.group_add_rounded,
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                      title: 'Buat Grup',
                      subtitle: 'Langsung bikin grup baru',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showCreateGroupDialog();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.login_rounded,
                      color: Colors.purple.shade700,
                      bgColor: Colors.purple.shade50,
                      title: 'Masuk Grup',
                      subtitle: 'Gabung pakai kode 6 digit',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showJoinGroupDialog();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Buat Grup Keluarga'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Grup',
            hintText: 'contoh: Keluarga Ridlo, Motor Kantor',
            border: OutlineInputBorder(),
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
            child: const Text('Buat Grup'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    try {
      await _db.createGroup(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grup "$name" berhasil dibuat!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal buat grup: $e')),
        );
      }
    }
  }

  Future<void> _showJoinGroupDialog() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login_rounded, color: Colors.purple),
            SizedBox(width: 8),
            Text('Masuk ke Grup'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Kode Undangan (6 Karakter)',
            hintText: 'contoh: ABC123',
            border: OutlineInputBorder(),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berhasil bergabung ke grup!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal gabung: $e')),
        );
      }
    }
  }

  bool _checkIsDue(Motorcycle moto) {
    final serviceDate = moto.lastServiceAt?.toDate();
    if (serviceDate != null) {
      final days = DateTime.now().difference(serviceDate).inDays;
      return days >= 30;
    }
    final days = DateTime.now().difference(moto.createdAt.toDate()).inDays;
    return days >= 30;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _buildMotorPage(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 68.0;
    const double topOffset = 24.0;
    final double totalHeight = barHeight + topOffset + bottomPadding;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Curved Cutout Background & Top Stroke
          Positioned.fill(
            child: CustomPaint(
              painter: CurvedNotchPainter(
                backgroundColor: Theme.of(context).colorScheme.surface,
                strokeColor: const Color(0xFFF1F5F9),
                topOffset: topOffset,
              ),
            ),
          ),

          // Nav Items Grid (Docked over the curved background)
          Positioned(
            left: 0,
            right: 0,
            top: topOffset,
            height: barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Left Group: Motor
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: _buildNavItem(
                          icon: Icons.two_wheeler_outlined,
                          activeIcon: Icons.two_wheeler_rounded,
                          label: 'Motor',
                          isSelected: _index == 0,
                          onTap: () => setState(() => _index = 0),
                        ),
                      ),
                    ),
                  ),

                  // Center Spacer for FAB (Matches cutout notch width)
                  const SizedBox(width: 56),

                  // Right Group: Profil
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _buildNavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Profil',
                          isSelected: _index == 1,
                          onTap: () => setState(() => _index = 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Elevated Central Circular FAB (+) in Notch
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCenterActionButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const inactiveIconColor = Color(0xFF94A3B8); // text-slate-400
    const inactiveTextColor = Color(0xFF64748B); // text-slate-500

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: primaryColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : inactiveIconColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : inactiveTextColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    return GestureDetector(
      onTap: _openActionSheet,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMotorPage() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final displayName = user?.displayName ?? 'Pengguna';
    final firstName = displayName.split(' ').first;

    return StreamBuilder<List<Motorcycle>>(
      stream: _db.getUserMotorcycles(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }
        final allMotos = snapshot.data ?? [];
        if (allMotos.isNotEmpty) {
          widget.notificationService.syncReminders(allMotos);
        }

        // Hitung ringkasan oli
        int dueCount = 0;
        int safeCount = 0;
        for (final m in allMotos) {
          final isDue = _checkIsDue(m);
          if (isDue) {
            dueCount++;
          } else {
            safeCount++;
          }
        }

        // Terapkan filter
        List<Motorcycle> filteredMotos = allMotos;
        if (_filter == 'private') {
          filteredMotos = allMotos.where((m) => !m.isGroupMotor).toList();
        } else if (_filter == 'group') {
          filteredMotos = allMotos.where((m) => m.isGroupMotor).toList();
        }

        return CustomScrollView(
          slivers: [
            // Modern Header
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Halo, $firstName! ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const Text('👋', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'MotorQu',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: user?.photoURL != null && user!.photoURL!.trim().isNotEmpty
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user?.photoURL == null || user!.photoURL!.trim().isEmpty
                            ? const Icon(Icons.person, size: 24)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allMotos.isNotEmpty) ...[
                      // Status Overview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade700, Colors.indigo.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              '${allMotos.length}',
                              'Total Motor',
                              Icons.two_wheeler_rounded,
                              Colors.white,
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            _buildStatItem(
                              '$safeCount',
                              'Oli Aman',
                              Icons.check_circle_outline_rounded,
                              Colors.greenAccent,
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            _buildStatItem(
                              '$dueCount',
                              'Perlu Dicek',
                              Icons.warning_amber_rounded,
                              dueCount > 0 ? Colors.amberAccent : Colors.white70,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'Semua (${allMotos.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'private',
                              'Pribadi (${allMotos.where((m) => !m.isGroupMotor).length})',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'group',
                              'Grup (${allMotos.where((m) => m.isGroupMotor).length})',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // Daftar Motor / Empty State
            filteredMotos.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(allMotos.isEmpty),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final moto = filteredMotos[index];
                          return _buildMotorCard(moto);
                        },
                        childCount: filteredMotos.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primary : Colors.grey.shade700,
      ),
      side: BorderSide(
        color: isSelected ? primary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildMotorCard(Motorcycle moto) {
    final isDue = _checkIsDue(moto);
    final serviceDate = moto.lastServiceAt?.toDate();
    final daysSince = serviceDate != null
        ? DateTime.now().difference(serviceDate).inDays
        : DateTime.now().difference(moto.createdAt.toDate()).inDays;
    final daysRemaining = 30 - daysSince;

    String dateStr = 'Belum dicatat';
    if (moto.lastServiceAt != null) {
      dateStr = DateFormat('dd MMM yyyy').format(moto.lastServiceAt!.toDate());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDue
              ? Colors.red.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.15),
          width: isDue ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MotorDetailScreen(motorcycle: moto),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row Atas: Nama, Plat, & Chip Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: moto.isGroupMotor
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.two_wheeler_rounded,
                      color: moto.isGroupMotor
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moto.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${moto.brand} ${moto.model}${moto.plate != null && moto.plate!.isNotEmpty ? " • ${moto.plate}" : ""}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: moto.isGroupMotor
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          moto.isGroupMotor ? Icons.group : Icons.person,
                          size: 12,
                          color: moto.isGroupMotor ? Colors.green.shade800 : Colors.blue.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          moto.isGroupMotor ? 'Grup' : 'Pribadi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: moto.isGroupMotor ? Colors.green.shade800 : Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Info Oli
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oli Terakhir ($dateStr)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,###').format(moto.lastOdometer)} KM',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Target Ganti Oli',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,###').format(moto.nextDueKm)} KM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDue ? Colors.red.shade700 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Status Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDue
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDue ? Icons.error_outline : Icons.check_circle_outline,
                      size: 14,
                      color: isDue ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isDue
                            ? 'Sudah $daysSince hari sejak ganti oli! Segera servis.'
                            : 'Kondisi aman (jadwal cek: ${daysRemaining > 0 ? "$daysRemaining hari lagi" : "hari ini"})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDue ? Colors.red.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTotalEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTotalEmpty ? 'Belum Ada Motor' : 'Tidak Ada Motor di Kategori Ini',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isTotalEmpty
                  ? 'Daftarkan motor pertamamu untuk mulai memantau jadwal ganti oli.'
                  : 'Coba pilih filter lain atau tambahkan motor baru.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/addMotor');
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Motor Sekarang'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter to render the curved notch cutout with crisp top stroke
/// exactly as designed in Stitch (viewBox: 0 0 390 68 with central cutout).
class CurvedNotchPainter extends CustomPainter {
  final Color backgroundColor;
  final Color strokeColor;
  final double topOffset;

  CurvedNotchPainter({
    required this.backgroundColor,
    required this.strokeColor,
    this.topOffset = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final top = topOffset;

    // Build the cutout notch path:
    // M0 0 H148 C158 0 162 5 166 14 C172 27 181 33 195 33 C209 33 218 27 224 14 C228 5 232 0 242 0 H390 V68 H0 V0 Z
    final path = Path();
    path.moveTo(0, top);
    path.lineTo(cx - 47, top);
    path.cubicTo(cx - 37, top, cx - 33, top + 5, cx - 29, top + 14);
    path.cubicTo(cx - 23, top + 27, cx - 14, top + 33, cx, top + 33);
    path.cubicTo(cx + 14, top + 33, cx + 23, top + 27, cx + 29, top + 14);
    path.cubicTo(cx + 33, top + 5, cx + 37, top, cx + 47, top);
    path.lineTo(w, top);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // 1. Soft upwards shadow: drop-shadow-[0_-5px_12px_rgba(0,0,0,0.06)]
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. Fill background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Top stroke with crisp finish: stroke="#f1f5f9" stroke-width="1.2"
    final strokePath = Path();
    strokePath.moveTo(0, top);
    strokePath.lineTo(cx - 47, top);
    strokePath.cubicTo(cx - 37, top, cx - 33, top + 5, cx - 29, top + 14);
    strokePath.cubicTo(cx - 23, top + 27, cx - 14, top + 33, cx, top + 33);
    strokePath.cubicTo(cx + 14, top + 33, cx + 23, top + 27, cx + 29, top + 14);
    strokePath.cubicTo(cx + 33, top + 5, cx + 37, top, cx + 47, top);
    strokePath.lineTo(w, top);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CurvedNotchPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.topOffset != topOffset;
  }
}
