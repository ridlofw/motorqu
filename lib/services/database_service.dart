import 'dart:async';
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

  /// Mengambil seluruh motor yang diakses oleh user (motor pribadi + motor dari semua grup yang diikuti).
  /// Menggunakan gabungan stream grup user dan query motor dengan whereIn groupId,
  /// sehingga saat user bergabung atau keluar grup, motor otomatis muncul/hilang secara real-time.
  Stream<List<Motorcycle>> getUserMotorcycles(String uid) {
    late StreamController<List<Motorcycle>> controller;
    StreamSubscription? groupSub;
    StreamSubscription? motoSub;

    controller = StreamController<List<Motorcycle>>.broadcast(
      onListen: () {
        groupSub = _db
            .collection('groups')
            .where('memberUids', arrayContains: uid)
            .snapshots()
            .listen((groupSnap) {
          final groupIds = groupSnap.docs.map((d) => d.id).toList();
          final allGroupIds = <String>{'private_$uid', ...groupIds}.take(30).toList();

          motoSub?.cancel();
          motoSub = _db
              .collection('motorcycles')
              .where('groupId', whereIn: allGroupIds)
              .snapshots()
              .listen(
            (motoSnap) {
              final motos = motoSnap.docs
                  .map((d) => Motorcycle.fromMap(d.data(), d.id))
                  .toList();
              if (!controller.isClosed) {
                controller.add(motos);
              }
            },
            onError: (err) {
              if (!controller.isClosed) {
                controller.addError(err);
              }
            },
          );
        }, onError: (err) {
          if (!controller.isClosed) {
            controller.addError(err);
          }
        });
      },
      onCancel: () {
        motoSub?.cancel();
        groupSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<String> addMotorcycle(Motorcycle moto) async {
    final uid = _uid!;
    final motoMap = moto.toMap();
    motoMap['createdBy'] = uid;
    motoMap['createdAt'] = Timestamp.now();

    final targetGroupId = (moto.groupId.isNotEmpty && moto.isGroupMotor)
        ? moto.groupId
        : 'private_$uid';
    motoMap['groupId'] = targetGroupId;
    motoMap['isGroupMotor'] = moto.isGroupMotor && targetGroupId != 'private_$uid';
    motoMap['memberUids'] = [uid];

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
    return _db
        .collection('motorcycles')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Motorcycle.fromMap(d.data(), d.id))
            .toList());
  }

  /// Mengambil daftar motor pribadi milik user (belum masuk grup mana pun)
  Future<List<Motorcycle>> getUserPrivateMotorcycles(String uid) async {
    final snapshot = await _db
        .collection('motorcycles')
        .where('groupId', isEqualTo: 'private_$uid')
        .get();
    final list = snapshot.docs
        .map((d) => Motorcycle.fromMap(d.data(), d.id))
        .toList();

    // Pastikan jika ada motor pribadi buatan user yang belum punya groupId atau bukan motor grup
    final createdSnap = await _db
        .collection('motorcycles')
        .where('createdBy', isEqualTo: uid)
        .get();
    for (final doc in createdSnap.docs) {
      final m = Motorcycle.fromMap(doc.data(), doc.id);
      if ((m.groupId.isEmpty || m.groupId == 'private_$uid' || !m.isGroupMotor) &&
          !list.any((existing) => existing.id == m.id)) {
        list.add(m);
      }
    }
    return list;
  }

  /// Memasukkan motor pribadi ke dalam grup
  Future<void> assignMotorcycleToGroup(String motoId, String groupId) async {
    final g = await _db.collection('groups').doc(groupId).get();
    final members = g.exists
        ? List<String>.from(g.data()!['memberUids'] ?? [_uid!])
        : [_uid!];

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
      'name': groupName.trim(),
      'ownerId': uid,
      'memberUids': [uid],
      'createdAt': Timestamp.now(),
    });
    return doc.id;
  }

  /// Membuat kode undangan unik 6 karakter (Bisa dipanggil oleh Anggota/Owner Grup)
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
  Future<List<Map<String, dynamic>>> getGroupMembers(FamilyGroup group) async {
    if (group.memberUids.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (final uid in group.memberUids) {
      try {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = Map<String, dynamic>.from(doc.data()!);
          data['uid'] = uid;
          result.add(data);
        } else {
          result.add({
            'uid': uid,
            'displayName': 'Anggota Keluarga',
            'email': '',
          });
        }
      } catch (_) {
        result.add({
          'uid': uid,
          'displayName': 'Anggota Keluarga',
          'email': '',
        });
      }
    }
    return result;
  }

  /// Bergabung ke grup menggunakan kode undangan.
  /// Mengembalikan groupId yang berhasil dimasuki.
  Future<String> joinGroupWithCode(String inviteCode) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    if (cleanCode.length != 6) {
      throw Exception('Kode undangan harus 6 karakter');
    }

    final inviteDoc = await _db.collection('invites').doc(cleanCode).get();
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

    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) {
      throw Exception('Grup yang dituju sudah tidak ada');
    }

    final currentMembers = List<String>.from(groupSnap.data()?['memberUids'] ?? []);
    if (currentMembers.contains(uid)) {
      throw Exception('Anda sudah menjadi anggota di grup ini');
    }

    // Tambahkan UID ke anggota grup
    await groupRef.update({
      'memberUids': FieldValue.arrayUnion([uid]),
      'lastInviteUsed': cleanCode,
    });

    // Hapus kode undangan agar tidak bisa dipakai orang lain lagi (single-use)
    try {
      await _db.collection('invites').doc(cleanCode).delete();
    } catch (_) {}

    return groupId;
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _uid!;
    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) return;

    final data = groupSnap.data()!;
    final ownerId = data['ownerId'] as String?;
    final members = List<String>.from(data['memberUids'] ?? []);

    if (members.length <= 1) {
      // Jika anggota terakhir keluar, hapus grup
      await groupRef.delete();
    } else {
      final updates = <String, dynamic>{
        'memberUids': FieldValue.arrayRemove([uid]),
      };
      // Jika owner yang keluar tapi masih ada anggota lain, alihkan owner ke anggota berikutnya
      if (ownerId == uid) {
        final remaining = members.where((m) => m != uid).toList();
        if (remaining.isNotEmpty) {
          updates['ownerId'] = remaining.first;
        }
      }
      await groupRef.update(updates);
    }

    // Kembalikan semua motor buatan user yang ada di grup ini kembali menjadi motor pribadi
    try {
      final myMotors = await _db
          .collection('motorcycles')
          .where('groupId', isEqualTo: groupId)
          .where('createdBy', isEqualTo: uid)
          .get();
      for (final doc in myMotors.docs) {
        await doc.reference.update({
          'groupId': 'private_$uid',
          'isGroupMotor': false,
          'memberUids': [uid],
        });
      }
    } catch (_) {}
  }

  /// Mengeluarkan anggota dari grup (hanya bisa dilakukan oleh Owner grup)
  Future<void> kickMember(String groupId, String targetUid) async {
    final uid = _uid;
    if (uid == null) throw Exception('Pengguna belum login');
    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) throw Exception('Grup tidak ditemukan');

    final data = groupSnap.data()!;
    final ownerId = data['ownerId'] as String?;
    if (ownerId != uid) {
      throw Exception('Hanya pemilik grup yang dapat mengeluarkan anggota');
    }

    await groupRef.update({
      'memberUids': FieldValue.arrayRemove([targetUid]),
    });

    // Kembalikan semua motor milik targetUid di grup ini kembali menjadi motor pribadi
    try {
      final targetMotors = await _db
          .collection('motorcycles')
          .where('groupId', isEqualTo: groupId)
          .where('createdBy', isEqualTo: targetUid)
          .get();
      for (final doc in targetMotors.docs) {
        await doc.reference.update({
          'groupId': 'private_$targetUid',
          'isGroupMotor': false,
          'memberUids': [targetUid],
        });
      }
    } catch (_) {}
  }

  /// Mengalihkan kepemilikan grup ke anggota lain (hanya bisa dilakukan oleh Owner grup)
  Future<void> transferGroupOwnership(String groupId, String newOwnerUid) async {
    final uid = _uid;
    if (uid == null) throw Exception('Pengguna belum login');
    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) throw Exception('Grup tidak ditemukan');

    final data = groupSnap.data()!;
    final ownerId = data['ownerId'] as String?;
    if (ownerId != uid) {
      throw Exception('Hanya pemilik grup yang dapat memindahkan kepemilikan');
    }

    final members = List<String>.from(data['memberUids'] ?? []);
    if (!members.contains(newOwnerUid)) {
      throw Exception('Pengguna tujuan bukan anggota grup ini');
    }

    await groupRef.update({
      'ownerId': newOwnerUid,
    });
  }

  Future<void> updateGroupName(String groupId, String newName) async {
    await _db.collection('groups').doc(groupId).update({'name': newName.trim()});
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
