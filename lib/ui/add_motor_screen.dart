import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/motorcycle.dart';
import '../models/group.dart';
import '../services/database_service.dart';

class AddMotorScreen extends StatefulWidget {
  final Motorcycle? moto;
  const AddMotorScreen({super.key, this.moto});

  @override
  State<AddMotorScreen> createState() => _AddMotorScreenState();
}

class _AddMotorScreenState extends State<AddMotorScreen> {
  final DatabaseService _db = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _brand;
  late TextEditingController _model;
  late TextEditingController _plate;
  late TextEditingController _year;
  late TextEditingController _color;
  late TextEditingController _kmInterval;
  late TextEditingController _initialKm;

  bool _isGroup = false;
  List<FamilyGroup> _userGroups = [];
  String? _selectedGroupId;
  bool _loadingGroup = true;
  bool _saving = false;

  bool get _isEdit => widget.moto != null;

  @override
  void initState() {
    super.initState();
    final m = widget.moto;
    _name = TextEditingController(text: m?.name ?? '');
    _brand = TextEditingController(text: m?.brand ?? '');
    _model = TextEditingController(text: m?.model ?? '');
    _plate = TextEditingController(text: m?.plate ?? '');
    _year = TextEditingController(text: m?.year ?? '');
    _color = TextEditingController(text: m?.color ?? '');
    _kmInterval = TextEditingController(
      text: (m?.reminderIntervalKm ?? 2000).toString(),
    );
    _initialKm = TextEditingController(
      text: (m?.lastOdometer ?? 0).toString(),
    );
    _isGroup = m?.isGroupMotor ?? false;
    _loadGroup();
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _plate.dispose();
    _year.dispose();
    _color.dispose();
    _kmInterval.dispose();
    _initialKm.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final groups = await _db.getUserGroupsList(uid);
    if (mounted) {
      setState(() {
        _userGroups = groups;
        _loadingGroup = false;
        if (_isEdit && widget.moto!.isGroupMotor && groups.any((g) => g.id == widget.moto!.groupId)) {
          _isGroup = true;
          _selectedGroupId = widget.moto!.groupId;
        } else if (groups.isNotEmpty) {
          _selectedGroupId = groups.first.id;
        } else {
          _isGroup = false;
          _selectedGroupId = null;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final interval = int.tryParse(_kmInterval.text.trim()) ?? 2000;
      final initialKm = int.tryParse(_initialKm.text.trim()) ?? 0;

      String targetGroupId;
      if (_isGroup && _selectedGroupId != null) {
        targetGroupId = _selectedGroupId!;
      } else {
        targetGroupId = 'private_$uid';
      }

      if (_isEdit) {
        final plateText = _plate.text.trim();
        final yearText = _year.text.trim();
        final colorText = _color.text.trim();

        await _db.updateMotorcycleFields(
          widget.moto!.id,
          name: _name.text.trim(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          plate: plateText.isEmpty ? null : plateText,
          year: yearText.isEmpty ? null : yearText,
          color: colorText.isEmpty ? null : colorText,
          clearPlate: plateText.isEmpty,
          clearYear: yearText.isEmpty,
          clearColor: colorText.isEmpty,
          reminderIntervalKm: interval,
          groupId: targetGroupId,
          isGroupMotor: _isGroup,
        );
      } else {
        final moto = Motorcycle(
          id: '',
          name: _name.text.trim(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          plate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
          year: _year.text.trim().isEmpty ? null : _year.text.trim(),
          color: _color.text.trim().isEmpty ? null : _color.text.trim(),
          groupId: targetGroupId,
          isGroupMotor: _isGroup,
          reminderIntervalKm: interval,
          lastOdometer: initialKm,
          createdBy: uid,
          createdAt: Timestamp.now(),
        );
        await _db.addMotorcycle(moto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Motor diperbarui' : 'Motor ditambahkan'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Motor' : 'Tambah Motor'),
      ),
      body: _loadingGroup
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nama Panggilan Motor *',
                      hintText: 'contoh: Beat Merah, Vario Hitam',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brand,
                    decoration: const InputDecoration(
                      labelText: 'Merk *',
                      hintText: 'Honda, Yamaha, Suzuki, dll',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Merk wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _model,
                    decoration: const InputDecoration(
                      labelText: 'Model *',
                      hintText: 'Beat CBS, Vario 160, NMax',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Model wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plate,
                    decoration: const InputDecoration(
                      labelText: 'Plat Nomor (opsional)',
                      hintText: 'B 1234 ABC',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Tahun (opsional)',
                            hintText: '2021',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _color,
                          decoration: const InputDecoration(
                            labelText: 'Warna (opsional)',
                            hintText: 'Hitam',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isEdit) ...[
                    TextFormField(
                      controller: _initialKm,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'KM Odometer Saat Ini *',
                        hintText: '0',
                        suffixText: 'KM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'KM wajib diisi';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'KM tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _kmInterval,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Interval Pengingat Ganti Oli (KM) *',
                      hintText: '2000',
                      suffixText: 'KM',
                      helperText: 'Standar 2000 KM atau sesuai rekomendasi pabrikan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Interval wajib diisi';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Interval harus > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    'Kepemilikan Motor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _isGroup,
                    onChanged: (v) => setState(() => _isGroup = v!),
                    title: const Text('Motor Pribadi'),
                    subtitle: const Text('Hanya terlihat di akun Anda'),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _isGroup,
                    onChanged: _userGroups.isEmpty
                        ? null
                        : (v) => setState(() => _isGroup = v!),
                    title: Text(
                      _userGroups.isEmpty
                          ? 'Bagikan ke Grup Keluarga (Belum ada grup)'
                          : 'Bagikan ke Grup Keluarga',
                    ),
                    subtitle: Text(
                      _userGroups.isEmpty
                          ? 'Buat atau gabung grup dulu lewat menu Profil.'
                          : 'Terlihat dan bisa dicatat oleh anggota grup.',
                    ),
                  ),
                  if (_isGroup && _userGroups.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Grup Tujuan *',
                          border: OutlineInputBorder(),
                        ),
                        items: _userGroups.map((g) {
                          return DropdownMenuItem<String>(
                            value: g.id,
                            child: Text(g.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGroupId = val);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Motor'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}