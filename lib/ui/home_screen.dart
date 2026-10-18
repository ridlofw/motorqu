import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  int _index = 0;

  void _openActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: const Text('Catat Oli'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/addOil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Tambah Motor'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/addMotor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Buat Grup'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/group');
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Masuk Grup'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/group');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('MotorQu')),
      body: StreamBuilder<List<Motorcycle>>(
        stream: _db.getUserMotorcycles(uid),
        builder: (context, snapshot) {
          if (_index == 1) return const SizedBox.shrink();

          if (_index == 2) return const ProfileScreen();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          final motorcycles = snapshot.data ?? [];
          return motorcycles.isEmpty ? _buildEmptyState() : _buildMotorList(motorcycles);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 1) {
            _openActionSheet();
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'Motor'),
          NavigationDestination(icon: Icon(Icons.add_circle, size: 32), label: ''),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.two_wheeler, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Motor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol (+) untuk menambah motor atau mengelola grup keluarga.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotorList(List<Motorcycle> motorcycles) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: motorcycles.length,
      itemBuilder: (context, index) {
        final moto = motorcycles[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.two_wheeler)),
            title: Text(
              moto.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${moto.brand} ${moto.model}\n'
              'Oli terakhir: ${moto.lastOdometer} KM · Target: ${moto.nextDueKm} KM',
            ),
            isThreeLine: true,
            trailing: Chip(
              label: Text(
                moto.isGroupMotor ? 'Grup' : 'Pribadi',
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: moto.isGroupMotor
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.blue.withValues(alpha: 0.15),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MotorDetailScreen(motorcycle: moto),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
