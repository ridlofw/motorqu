import 'package:cloud_firestore/cloud_firestore.dart';

class OilRecord {
  final String id;
  final String motorcycleId;
  final Timestamp performedAt;
  final int odometer;
  final String performedBy;
  final Timestamp createdAt;

  OilRecord({
    required this.id,
    required this.motorcycleId,
    required this.performedAt,
    required this.odometer,
    required this.performedBy,
    required this.createdAt,
  });

  factory OilRecord.fromMap(Map<String, dynamic> data, String docId) {
    return OilRecord(
      id: docId,
      motorcycleId: data['motorcycleId'] ?? '',
      performedAt: data['performedAt'] ?? Timestamp.now(),
      odometer: data['odometer'] ?? 0,
      performedBy: data['performedBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'motorcycleId': motorcycleId,
      'performedAt': performedAt,
      'odometer': odometer,
      'performedBy': performedBy,
      'createdAt': createdAt,
    };
  }
}
