import 'package:flutter/material.dart';
import 'schedule_rules.dart';
import 'shift_window.dart';

class ScheduleRequest {
  const ScheduleRequest({
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.seciliHaftaGunleri,
    required this.vardiyalar,
    required this.kurallar,
  });

  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final List<int> seciliHaftaGunleri;
  final List<ShiftWindow> vardiyalar;
  final ScheduleRules kurallar;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'baslangicTarihi': baslangicTarihi.toIso8601String(),
      'bitisTarihi': bitisTarihi.toIso8601String(),
      'seciliHaftaGunleri': seciliHaftaGunleri,
      'vardiyalar': vardiyalar.map((e) => e.toMap()).toList(),
      'kurallar': kurallar.toMap(),
    };
  }

  factory ScheduleRequest.fromMap(Map<String, dynamic> map) {
    final int legacyDuration = (map['nobetSuresiSaat'] as int?) ?? 12;
    final List<ShiftWindow> fallback = <ShiftWindow>[
      ShiftWindow(
        id: 'legacy-1',
        start: const TimeOfDay(hour: 8, minute: 0),
        end: TimeOfDay(hour: (8 + legacyDuration) % 24, minute: 0),
      ),
    ];

    return ScheduleRequest(
      baslangicTarihi: DateTime.parse(map['baslangicTarihi'] as String),
      bitisTarihi: DateTime.parse(map['bitisTarihi'] as String),
      seciliHaftaGunleri: (map['seciliHaftaGunleri'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          <int>[
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
      vardiyalar: (map['vardiyalar'] as List<dynamic>?)
              ?.map((e) => ShiftWindow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          fallback,
      kurallar: ScheduleRules.fromMap(map['kurallar'] as Map<String, dynamic>),
    );
  }
}

