class UnfilledSlot {
  const UnfilledSlot({
    required this.locationId,
    required this.shiftStart,
    required this.shiftEnd,
    required this.reason,
  });

  final int locationId;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final String reason;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'locationId': locationId,
      'shiftStart': shiftStart.toIso8601String(),
      'shiftEnd': shiftEnd.toIso8601String(),
      'reason': reason,
    };
  }

  factory UnfilledSlot.fromMap(Map<String, dynamic> map) {
    return UnfilledSlot(
      locationId: map['locationId'] as int,
      shiftStart: DateTime.parse(map['shiftStart'] as String),
      shiftEnd: DateTime.parse(map['shiftEnd'] as String),
      reason: map['reason'] as String,
    );
  }
}
