import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/motorcycle.dart';
import '../models/oil_record.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_motor_screen.dart';

/// Form pencatatan ganti oli. Hanya tanggal & KM yang wajib (lihat SPEC.md).
class AddOilScreen extends StatefulWidget {
  final String? preselectMotorId;
  const AddOilScreen({super.key, this.preselectMotorId});

  @override
  State<AddOilScreen> createState() => _AddOilScreenState();
}

class _AddOilScreenState extends State<AddOilScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _km = TextEditingController();

  DateTime _tanggal = DateTime.now();
  Motorcycle? _selected;
  bool _saving = false;

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _save() async {
    final moto = _selected;
    if (moto == null) {
      _toast('Pilih motor dulu yaa');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = FirebaseAuth.instance.currentUser;
      final km = int.parse(_km.text.trim());

      final record = OilRecord(
        id: '',
        motorcycleId: moto.id,
        performedAt: Timestamp.fromDate(_tanggal),
        odometer: km,
        performedBy: user?.displayName ?? uid,
        createdAt: Timestamp.now(),
      );

      await _db.addOilRecord(moto.id, record);
      await _scheduleReminder(moto, km);

      if (!mounted) return;
      _toast('Berhasil dicatat');
      Navigator.pop(context, true);
    } catch (e) {
      _toast('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scheduleReminder(Motorcycle moto, int km) async {
    final target = km + moto.reminderIntervalKm;
    await _notif.scheduleOilReminder(
      id: moto.id.hashCode,
      title: 'Cek oli ${moto.name}',
      body: 'Jika KM motor ${moto.name} sudah lebih dari ${target}KM, '
          'jangan lupa ganti oli yaa',
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Ganti Oli')),
      body: StreamBuilder<List<Motorcycle>>(
        stream: _db.getUserMotorcycles(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final motos = snapshot.data ?? [];

          if (motos.isEmpty) {
            return _emptyMotors();
          }

          // pra-pilih motor kalau dipanggil dari notifikasi
          if (_selected == null) {
            final wanted = widget.preselectMotorId;
            for (final m in motos) {
              if (m.id == wanted) _selected = m;
            }
            _selected ??= motos.first;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Motor'),
                const SizedBox(height: 8),
                DropdownButtonFormField<Motorcycle>(
                  initialValue: _selected,
                  items: motos.map((m) {
                    return DropdownMenuItem<Motorcycle>(
                      value: m,
                      child: Text(m.name),
                    );
                  }).toList(),
                  onChanged: (m) => setState(() => _selected = m),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Text('Tanggal ganti oli *'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd MMMM yyyy').format(_tanggal)),
                ),
                const SizedBox(height: 20),
                const Text('KM saat ini *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _km,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'contoh: 12500',
                    suffixText: 'KM',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'KM wajib diisi';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'KM tidak valid';
                    final last = _selected?.lastOdometer ?? 0;
                    if (n < last) return 'KM harus >= KM terakhir ($last)';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyMotors() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.motorcycle, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum ada motor. Tambah motor dulu sebelum mencatat oli.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMotorScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Motor'),
            ),
          ],
        ),
      ),
    );
  }
}
