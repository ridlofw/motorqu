import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final String ownerId; // Pembuat grup utama (creator)
  final List<String> ownerIds; // Seluruh admin/owner grup (bisa banyak)
  final List<String> memberUids;
  final Timestamp createdAt;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    this.ownerIds = const [],
    required this.memberUids,
    required this.createdAt,
  });

  /// Cek apakah pengguna dengan uid tertentu adalah salah satu owner/admin
  bool isOwner(String uid) =>
      ownerIds.contains(uid) || (ownerId.isNotEmpty && ownerId == uid);

  factory FamilyGroup.fromMap(Map<String, dynamic> data, String docId) {
    final ownerId = data['ownerId'] ?? '';
    final List<String> ownerIdsList = data['ownerIds'] != null
        ? List<String>.from(data['ownerIds'])
        : (ownerId.isNotEmpty ? <String>[ownerId] : <String>[]);

    return FamilyGroup(
      id: docId,
      name: data['name'] ?? '',
      ownerId: ownerId,
      ownerIds: ownerIdsList,
      memberUids: List<String>.from(data['memberUids'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'ownerIds': ownerIds.isNotEmpty
          ? ownerIds
          : (ownerId.isNotEmpty ? <String>[ownerId] : <String>[]),
      'memberUids': memberUids,
      'createdAt': createdAt,
    };
  }
}
