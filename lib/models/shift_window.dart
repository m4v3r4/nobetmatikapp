import 'package:flutter/material.dart';

class ShiftWindow {
  const ShiftWindow({
    required this.id,
    required this.start,
    required this.end,
  });

  final String id;
  final TimeOfDay start;
  final TimeOfDay end;

  ShiftWindow copyWith({TimeOfDay? start, TimeOfDay? end}) {
    return ShiftWindow(
      id: id,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'startHour': start.hour,
      'startMinute': start.minute,
      'endHour': end.hour,
      'endMinute': end.minute,
    };
  }

  factory ShiftWindow.fromMap(Map<String, dynamic> map) {
    return ShiftWindow(
      id: map['id'] as String,
      start: TimeOfDay(
        hour: map['startHour'] as int,
        minute: map['startMinute'] as int,
      ),
      end: TimeOfDay(
        hour: map['endHour'] as int,
        minute: map['endMinute'] as int,
      ),
    );
  }
}
