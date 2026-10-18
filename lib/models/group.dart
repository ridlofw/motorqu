import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberUids;
  final Timestamp createdAt;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberUids,
    required this.createdAt,
  });

  factory FamilyGroup.fromMap(Map<String, dynamic> data, String docId) {
    return FamilyGroup(
      id: docId,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberUids: List<String>.from(data['memberUids'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberUids': memberUids,
      'createdAt': createdAt,
    };
  }
}
