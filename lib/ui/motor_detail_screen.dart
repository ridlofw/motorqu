import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/motorcycle.dart';
import '../models/oil_record.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_motor_screen.dart';
import 'add_oil_screen.dart';

class MotorDetailScreen extends StatefulWidget {
  final Motorcycle motorcycle;
  const MotorDetailScreen({super.key, required this.motorcycle});

  @override
  State<MotorDetailScreen> createState() => _MotorDetailScreenState();
}

class _MotorDetailScreenState extends State<MotorDetailScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteOilRecord(OilRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan Oli'),
        content: Text(
          'Hapus catatan oli pada ${r.odometer} KM '
          '(${DateFormat('dd MMM yyyy').format(r.performedAt.toDate())})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.deleteOilRecord(widget.motorcycle.id, r.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan oli berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  Future<void> _deleteMotor(Motorcycle moto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Motor Permanen'),
        content: Text(
          'Yakin hapus motor "${moto.name}" beserta semua riwayat olinya secara permanen? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _db.deleteMotorcycle(moto.id);
    await _notif.cancel(moto.id.hashCode & 0x7FFFFFFF);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<Motorcycle?>(
      stream: _db.getMotorcycleStream(widget.motorcycle.id),
      builder: (context, motoSnap) {
        final moto = motoSnap.data ?? widget.motorcycle;
        final isCreator = moto.createdBy == myUid;

        return Scaffold(
          appBar: AppBar(
            title: Text(moto.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddMotorScreen(moto: moto)),
                  );
                },
              ),
              if (isCreator)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Hapus Motor Permanen',
                  onPressed: () => _deleteMotor(moto),
                ),
            ],
          ),
          body: StreamBuilder<List<OilRecord>>(
            stream: _db.getOilRecordsStream(moto.id),
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddOilScreen(preselectMotorId: moto.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.build_circle),
                    label: const Text('Catat Ganti Oli'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat Oli',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  records.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('Belum ada riwayat ganti oli.'),
                          ),
                        )
                      : _buildTimeline(records),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Info Motor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Merk', value: moto.brand),
                  _InfoRow(label: 'Model', value: moto.model),
                  if (moto.plate != null && moto.plate!.isNotEmpty)
                    _InfoRow(label: 'Plat', value: moto.plate!),
                  if (moto.year != null && moto.year!.isNotEmpty)
                    _InfoRow(label: 'Tahun', value: moto.year!),
                  if (moto.color != null && moto.color!.isNotEmpty)
                    _InfoRow(label: 'Warna', value: moto.color!),
                  _InfoRow(label: 'KM Terakhir', value: '${moto.lastOdometer} KM'),
                  _InfoRow(
                    label: 'Target Oli Berikutnya',
                    value: '${moto.nextDueKm} KM',
                  ),
                  _InfoRow(
                    label: 'Interval Pengingat',
                    value: '${moto.reminderIntervalKm} KM',
                  ),
                  _InfoRow(
                    label: 'Kepemilikan',
                    value: moto.isGroupMotor ? 'Grup Keluarga' : 'Pribadi',
                  ),
                  if (isCreator) ...[
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: () => _deleteMotor(moto),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Hapus Motor Permanen',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _oilDot() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }

  Widget _buildTimeline(List<OilRecord> records) {
    return Column(
      children: List.generate(records.length, (i) {
        final r = records[i];
        final last = '${r.odometer}';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _oilDot(),
                if (i != records.length - 1)
                  SizedBox(
                    width: 2,
                    height: 72,
                    child: ColoredBox(
                      color: Colors.blue.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      '$last KM',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy').format(r.performedAt.toDate())} • '
                      '${r.performedByName?.isNotEmpty == true ? r.performedByName! : r.performedBy}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      tooltip: 'Hapus Catatan Ini',
                      onPressed: () => _deleteOilRecord(r),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
