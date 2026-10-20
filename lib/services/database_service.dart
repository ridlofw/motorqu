import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/motorcycle.dart';
import '../models/oil_record.dart';
import '../models/group.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ----------------------------- MOTORCYCLES -----------------------------

  /// Mengambil seluruh motor yang diakses oleh user (motor pribadi + motor grup).
  /// Rules sekarang menggunakan field `memberUids` yang di-denormalisasi, jadi
  /// cukup satu query `arrayContains` — tanpa perlu `get()` pada dokumen grup.
  Stream<List<Motorcycle>> getUserMotorcycles(String uid) {
    final query = _db
        .collection('motorcycles')
        .where('memberUids', arrayContains: uid)
        .snapshots();
    return query.map((s) => s.docs
        .map((d) => Motorcycle.fromMap(d.data(), d.id))
        .toList());
  }

  Future<String> addMotorcycle(Motorcycle moto) async {
    final uid = _uid!;
    final motoMap = moto.toMap();
    // Tambahkan memberUids berdasarkan groupId untuk memudahkan Rules
    if (moto.groupId == 'private_$uid') {
      motoMap['memberUids'] = [uid];
    } else {
      // Ambil memberUids dari grup keluarga
      final g = await _db.collection('groups').doc(moto.groupId).get();
      motoMap['memberUids'] = g.exists ? g.data()!['memberUids'] : [uid];
    }

    final doc = await _db.collection('motorcycles').add(motoMap);
    return doc.id;
  }

  Future<void> updateMotorcycle(String id, Map<String, dynamic> updates) async {
    await _db.collection('motorcycles').doc(id).update(updates);
  }

  Future<void> deleteMotorcycle(String id) async {
    await _db.collection('motorcycles').doc(id).delete();
  }

  // ----------------------------- OIL RECORDS -----------------------------

  Future<void> addOilRecord(String motorcycleId, OilRecord record) async {
    await _db
        .collection('motorcycles')
        .doc(motorcycleId)
        .collection('records')
        .add(record.toMap());

    // Update metadata di dokumen induk motor (agar cepat di-load di dashboard)
    await _db.collection('motorcycles').doc(motorcycleId).update({
      'lastOdometer': record.odometer,
      'lastServiceAt': record.performedAt,
    });
  }

  Future<List<OilRecord>> getOilRecords(String motorcycleId) async {
    final snapshot = await _db
        .collection('motorcycles')
        .doc(motorcycleId)
        .collection('records')
        .orderBy('performedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => OilRecord.fromMap(doc.data(), doc.id)).toList();
  }

  /// Hapus satu catatan oli (misal jika terduplikasi)
  Future<void> deleteOilRecord(String motorcycleId, String recordId) async {
    await _db
        .collection('motorcycles')
        .doc(motorcycleId)
        .collection('records')
        .doc(recordId)
        .delete();

    final remaining = await getOilRecords(motorcycleId);
    if (remaining.isNotEmpty) {
      await _db.collection('motorcycles').doc(motorcycleId).update({
        'lastOdometer': remaining.first.odometer,
        'lastServiceAt': remaining.first.performedAt,
      });
    }
  }

  // ----------------------------- GROUPS -----------------------------

  /// Cari grup di mana user ini menjadi member (kompatibilitas backward)
  Future<FamilyGroup?> getUserGroup(String uid) async {
    final snapshot =
        await _db.collection('groups').where('memberUids', arrayContains: uid).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return FamilyGroup.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  /// Stream seluruh grup yang diikuti oleh user (Multi-Grup)
  Stream<List<FamilyGroup>> getUserGroups(String uid) {
    return _db
        .collection('groups')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FamilyGroup.fromMap(d.data(), d.id))
            .toList());
  }

  /// Mengambil daftar semua grup yang diikuti oleh user
  Future<List<FamilyGroup>> getUserGroupsList(String uid) async {
    final snapshot = await _db
        .collection('groups')
        .where('memberUids', arrayContains: uid)
        .get();
    return snapshot.docs
        .map((d) => FamilyGroup.fromMap(d.data(), d.id))
        .toList();
  }

  /// Stream semua motor yang ada di dalam sebuah grup
  Stream<List<Motorcycle>> getGroupMotorcycles(String groupId) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('motorcycles')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Motorcycle.fromMap(d.data(), d.id))
            .where((m) => m.groupId == groupId)
            .toList());
  }

  /// Mengambil daftar motor pribadi milik user (belum masuk grup mana pun)
  Future<List<Motorcycle>> getUserPrivateMotorcycles(String uid) async {
    final snapshot = await _db
        .collection('motorcycles')
        .where('memberUids', arrayContains: uid)
        .get();
    return snapshot.docs
        .map((d) => Motorcycle.fromMap(d.data(), d.id))
        .where((m) => m.groupId == 'private_$uid' || !m.isGroupMotor)
        .toList();
  }

  /// Memasukkan motor pribadi ke dalam grup
  Future<void> assignMotorcycleToGroup(String motoId, String groupId) async {
    final g = await _db.collection('groups').doc(groupId).get();
    if (!g.exists) throw Exception('Grup tidak ditemukan');
    final members = List<String>.from(g.data()!['memberUids'] ?? [_uid!]);

    await _db.collection('motorcycles').doc(motoId).update({
      'groupId': groupId,
      'isGroupMotor': true,
      'memberUids': members,
    });
  }

  /// Mengeluarkan motor dari grup kembali menjadi motor pribadi
  Future<void> removeMotorcycleFromGroup(String motoId, String uid) async {
    await _db.collection('motorcycles').doc(motoId).update({
      'groupId': 'private_$uid',
      'isGroupMotor': false,
      'memberUids': [uid],
    });
  }

  Future<String> createGroup(String groupName) async {
    final uid = _uid!;
    final doc = await _db.collection('groups').add({
      'name': groupName,
      'ownerId': uid,
      'memberUids': [uid],
      'createdAt': Timestamp.now(),
    });
    return doc.id;
  }

  /// Membuat kode undangan unik 6 karakter (Hanya bisa dipanggil oleh Owner Grup)
  Future<String> createInviteCode(String groupId) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();

    final expiresAt = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7))); // Kode berlaku 7 hari

    await _db.collection('invites').doc(code).set({
      'groupId': groupId,
      'createdBy': _uid!,
      'expiresAt': expiresAt,
    });

    return code;
  }

  /// Mengambil detail anggota grup lainnya.
  /// Catatan: rules melarang `list` pada users, jadi each doc di-get() manual.
  Future<List<Map<String, dynamic>>> getGroupMembers(FamilyGroup group) async {
    if (group.memberUids.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (final uid in group.memberUids) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = uid;
        result.add(data);
      }
    }
    return result;
  }

  /// Bergabung ke grup menggunakan kode undangan.
  Future<void> joinGroupWithCode(String inviteCode) async {
    final inviteDoc = await _db.collection('invites').doc(inviteCode).get();

    if (!inviteDoc.exists) {
      throw Exception('Kode undangan tidak ditemukan atau sudah dipakai');
    }

    final inviteData = inviteDoc.data()!;
    final expiresAt = (inviteData['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Kode undangan sudah kedaluwarsa');
    }

    final groupId = inviteData['groupId'] as String;
    final uid = _uid!;

    // Update langsung; rules (selfJoin) yang memvalidasi transisi keanggotaan.
    // Tidak boleh pakai transaction.get() karena member baru tidak punya
    // hak baca dokumen grup sebelum bergabung.
    try {
      await _db.collection('groups').doc(groupId).update({
        'memberUids': FieldValue.arrayUnion([uid]),
        'lastInviteUsed': inviteCode,
      });

      // Sinkronisasi memberUids ke semua motor di grup ini agar Rules tetap
      // bisa dihitung tanpa `get()` (denormalisasi).
      final motoSnapshot = await _db
          .collection('motorcycles')
          .where('groupId', isEqualTo: groupId)
          .get();
      for (final doc in motoSnapshot.docs) {
        final current = List<String>.from(doc.data()['memberUids'] ?? []);
        if (!current.contains(uid)) {
          current.add(uid);
          await doc.reference.update({'memberUids': current});
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Kode undangan tidak valid atau kamu sudah di grup ini');
      }
      rethrow;
    }

    // Kode dipakai sekali: hapus (boleh oleh member grup according to rules).
    try {
      await _db.collection('invites').doc(inviteCode).delete();
    } catch (_) {
      // bukan owner/member? biarkan kedaluwarsa sendiri (7 hari).
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _uid!;
    final groupRef = _db.collection('groups').doc(groupId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);
      if (!snapshot.exists) return;

      final currentMembers = List<String>.from(snapshot.data()!['memberUids'] ?? []);
      currentMembers.remove(uid);
      transaction.update(groupRef, {'memberUids': currentMembers});

      // Sinkronisasi memberUids ke motor di grup ini.
      final motoSnapshot =
          await _db.collection('motorcycles').where('groupId', isEqualTo: groupId).get();
      for (final doc in motoSnapshot.docs) {
        final motoMembers =
            List<String>.from(doc.data()['memberUids'] ?? []);
        motoMembers.remove(uid);
        transaction.update(doc.reference, {'memberUids': motoMembers});
      }
    });
  }

  Future<void> updateGroupName(String groupId, String newName) async {
    await _db.collection('groups').doc(groupId).update({'name': newName});
  }

  /// Stream riwayat oli (urut terbaru dulu) — dipakai di layar detail motor.
  Stream<List<OilRecord>> getOilRecordsStream(String motorcycleId) {
    return _db
        .collection('motorcycles')
        .doc(motorcycleId)
        .collection('records')
        .orderBy('performedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => OilRecord.fromMap(d.data(), d.id))
            .toList());
  }

  /// Ubah motor (nama, merk, model, plat, tahun, warna, interval KM, grup).
  Future<void> updateMotorcycleFields(
    String id, {
    String? name,
    String? brand,
    String? model,
    String? plate,
    String? year,
    String? color,
    int? reminderIntervalKm,
    String? groupId,
    bool? isGroupMotor,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (brand != null) data['brand'] = brand;
    if (model != null) data['model'] = model;
    if (plate != null) data['plate'] = plate;
    if (year != null) data['year'] = year;
    if (color != null) data['color'] = color;
    if (reminderIntervalKm != null) data['reminderIntervalKm'] = reminderIntervalKm;
    if (isGroupMotor != null) data['isGroupMotor'] = isGroupMotor;

    if (groupId != null) {
      data['groupId'] = groupId;
      final uid = _uid!;
      if (groupId.startsWith('private_')) {
        data['memberUids'] = [uid];
        data['isGroupMotor'] = false;
      } else {
        final g = await _db.collection('groups').doc(groupId).get();
        if (g.exists) {
          data['memberUids'] = List<String>.from(g.data()!['memberUids'] ?? [uid]);
          data['isGroupMotor'] = true;
        }
      }
    }

    await _db.collection('motorcycles').doc(id).update(data);
  }

  /// Ambil profil user (displayName, email, photoUrl) untuk layar profil.
  Stream<Map<String, dynamic>?> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((s) => s.data());
  }
}
