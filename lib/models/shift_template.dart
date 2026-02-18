import 'package:flutter/material.dart';

class ShiftTemplate {
  const ShiftTemplate({
    required this.id,
    required this.locationId,
    required this.baslangicSaati,
    required this.bitisSaati,
  });

  final int id;
  final int locationId;
  final TimeOfDay baslangicSaati;
  final TimeOfDay bitisSaati;

  double get sureSaat {
    final int start = baslangicSaati.hour * 60 + baslangicSaati.minute;
    int end = bitisSaati.hour * 60 + bitisSaati.minute;
    if (end <= start) {
      end += 24 * 60;
    }
    return (end - start) / 60;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'locationId': locationId,
      'startHour': baslangicSaati.hour,
      'startMinute': baslangicSaati.minute,
      'endHour': bitisSaati.hour,
      'endMinute': bitisSaati.minute,
    };
  }

  factory ShiftTemplate.fromMap(Map<String, dynamic> map) {
    return ShiftTemplate(
      id: map['id'] as int,
      locationId: map['locationId'] as int,
      baslangicSaati: TimeOfDay(
        hour: map['startHour'] as int,
        minute: map['startMinute'] as int,
      ),
      bitisSaati: TimeOfDay(
        hour: map['endHour'] as int,
        minute: map['endMinute'] as int,
      ),
    );
  }
}
