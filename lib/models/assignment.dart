class Assignment {
  const Assignment({
    required this.tarih,
    required this.locationId,
    required this.shiftStart,
    required this.shiftEnd,
    required this.durationHours,
    required this.personId,
  });

  final DateTime tarih;
  final int locationId;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final double durationHours;
  final int personId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tarih': tarih.toIso8601String(),
      'locationId': locationId,
      'shiftStart': shiftStart.toIso8601String(),
      'shiftEnd': shiftEnd.toIso8601String(),
      'durationHours': durationHours,
      'personId': personId,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      tarih: DateTime.parse(map['tarih'] as String),
      locationId: map['locationId'] as int,
      shiftStart: DateTime.parse(map['shiftStart'] as String),
      shiftEnd: DateTime.parse(map['shiftEnd'] as String),
      durationHours: (map['durationHours'] as num).toDouble(),
      personId: map['personId'] as int,
    );
  }
}
