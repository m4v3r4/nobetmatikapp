import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class PersistedState {
  const PersistedState({
    required this.people,
    required this.locations,
    required this.personSeq,
    required this.locationSeq,
    required this.periodStart,
    required this.periodEnd,
    required this.vardiyalar,
    required this.seciliHaftaGunleri,
    required this.minRestHours,
    required this.weeklyMaxShifts,
    required this.themeMode,
    required this.lastResult,
  });

  final List<Person> people;
  final List<DutyLocation> locations;
  final int personSeq;
  final int locationSeq;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ShiftWindow> vardiyalar;
  final List<int> seciliHaftaGunleri;
  final int minRestHours;
  final int weeklyMaxShifts;
  final String themeMode;
  final ScheduleResult? lastResult;
}

class LocalStorageService {
  static const String _stateKey = 'nobetmatik_state_v1';

  Future<PersistedState?> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;

    final List<Person> people = (data['people'] as List<dynamic>)
        .map((e) => Person.fromMap(e as Map<String, dynamic>))
        .toList();
    final List<DutyLocation> locations = (data['locations'] as List<dynamic>)
        .map((e) => DutyLocation.fromMap(e as Map<String, dynamic>))
        .toList();

    final Map<String, dynamic>? rawResult = data['lastResult'] == null
        ? null
        : data['lastResult'] as Map<String, dynamic>;

    final DateTime periodStart = DateTime.parse(
      (data['periodStart'] as String?) ?? DateTime.now().toIso8601String(),
    );

    DateTime periodEnd;
    if (data['periodEnd'] is String) {
      periodEnd = DateTime.parse(data['periodEnd'] as String);
    } else {
      final String? oldType = data['periodType'] as String?;
      if (oldType == 'monthly') {
        periodEnd = DateTime(periodStart.year, periodStart.month + 1, 1)
            .subtract(const Duration(days: 1));
      } else {
        periodEnd = periodStart.add(const Duration(days: 6));
      }
    }

    return PersistedState(
      people: people,
      locations: locations,
      personSeq: (data['personSeq'] as int?) ?? (people.length + 1),
      locationSeq: (data['locationSeq'] as int?) ?? (locations.length + 1),
      periodStart: periodStart,
      periodEnd: periodEnd,
      vardiyalar: (data['vardiyalar'] as List<dynamic>?)
              ?.map((e) => ShiftWindow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          <ShiftWindow>[
            ShiftWindow(
              id: 'legacy-1',
              start: const TimeOfDay(hour: 8, minute: 0),
              end: TimeOfDay(
                hour: (8 + ((data['nobetSuresiSaat'] as int?) ?? 12)) % 24,
                minute: 0,
              ),
            ),
          ],
      seciliHaftaGunleri: (data['seciliHaftaGunleri'] as List<dynamic>?)
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
      minRestHours: (data['minRestHours'] as int?) ?? 24,
      weeklyMaxShifts: (data['weeklyMaxShifts'] as int?) ?? 2,
      themeMode: (data['themeMode'] as String?) ?? 'light',
      lastResult: rawResult == null ? null : ScheduleResult.fromMap(rawResult),
    );
  }

  Future<void> save(PersistedState state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = <String, dynamic>{
      'people': state.people.map((e) => e.toMap()).toList(),
      'locations': state.locations.map((e) => e.toMap()).toList(),
      'personSeq': state.personSeq,
      'locationSeq': state.locationSeq,
      'periodStart': state.periodStart.toIso8601String(),
      'periodEnd': state.periodEnd.toIso8601String(),
      'vardiyalar': state.vardiyalar.map((e) => e.toMap()).toList(),
      'seciliHaftaGunleri': state.seciliHaftaGunleri,
      'minRestHours': state.minRestHours,
      'weeklyMaxShifts': state.weeklyMaxShifts,
      'themeMode': state.themeMode,
      'lastResult': state.lastResult?.toMap(),
    };
    await prefs.setString(_stateKey, jsonEncode(data));
  }
}

