import 'package:cloud_firestore/cloud_firestore.dart';

class Motorcycle {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String? plate;
  final String? year;
  final String? color;
  final String groupId; // Bisa berisi 'private_{uid}' atau 'groupId_familia'
  final bool isGroupMotor;
  final int reminderIntervalKm;
  final int lastOdometer;
  final Timestamp? lastServiceAt;
  final List<String> memberUids;
  final String createdBy;
  final Timestamp createdAt;

  Motorcycle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    this.plate,
    this.year,
    this.color,
    required this.groupId,
    this.isGroupMotor = false,
    this.reminderIntervalKm = 2000,
    this.lastOdometer = 0,
    this.lastServiceAt,
    this.memberUids = const [],
    required this.createdBy,
    required this.createdAt,
  });

  /// Target KM berikutnya: lastOdometer + reminderIntervalKm
  int get nextDueKm => lastOdometer + reminderIntervalKm;

  /// Status penggantian oli
  String get status {
    // Status dihitung manual oleh user atau nanti bisa ditambah update otomatis.
    return 'Aman';
  }

  Motorcycle copyWith({
    String? name,
    String? brand,
    String? model,
    String? plate,
    String? year,
    String? color,
    String? groupId,
    bool? isGroupMotor,
    int? reminderIntervalKm,
    int? lastOdometer,
    Timestamp? lastServiceAt,
    List<String>? memberUids,
  }) {
    return Motorcycle(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plate: plate ?? this.plate,
      year: year ?? this.year,
      color: color ?? this.color,
      groupId: groupId ?? this.groupId,
      isGroupMotor: isGroupMotor ?? this.isGroupMotor,
      reminderIntervalKm: reminderIntervalKm ?? this.reminderIntervalKm,
      lastOdometer: lastOdometer ?? this.lastOdometer,
      lastServiceAt: lastServiceAt ?? this.lastServiceAt,
      memberUids: memberUids ?? this.memberUids,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory Motorcycle.fromMap(Map<String, dynamic> data, String docId) {
    return Motorcycle(
      id: docId,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      plate: data['plate'],
      year: data['year'],
      color: data['color'],
      groupId: data['groupId'] ?? '',
      isGroupMotor: data['isGroupMotor'] ?? false,
      reminderIntervalKm: data['reminderIntervalKm'] ?? 2000,
      lastOdometer: data['lastOdometer'] ?? 0,
      lastServiceAt: data['lastServiceAt'],
      memberUids: List<String>.from(data['memberUids'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      'plate': plate,
      'year': year,
      'color': color,
      'groupId': groupId,
      'isGroupMotor': isGroupMotor,
      'reminderIntervalKm': reminderIntervalKm,
      'lastOdometer': lastOdometer,
      'lastServiceAt': lastServiceAt,
      'memberUids': memberUids,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Motorcycle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
