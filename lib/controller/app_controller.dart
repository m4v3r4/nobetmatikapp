import 'dart:collection';

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../services/scheduler_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required LocalStorageService storage,
    required SchedulerService scheduler,
  }) : _storage = storage,
       _scheduler = scheduler;

  final LocalStorageService _storage;
  final SchedulerService _scheduler;

  final List<Person> _people = <Person>[];
  final List<DutyLocation> _locations = <DutyLocation>[];

  int _personSeq = 1;
  int _locationSeq = 1;

  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now().add(const Duration(days: 6));
  List<ShiftWindow> _vardiyalar = <ShiftWindow>[
    const ShiftWindow(
      id: 'default-1',
      start: TimeOfDay(hour: 8, minute: 0),
      end: TimeOfDay(hour: 20, minute: 0),
    ),
  ];
  List<int> _seciliHaftaGunleri = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];
  int _minRestHours = 24;
  int _weeklyMaxShifts = 2;
  ThemeMode _themeMode = ThemeMode.light;
  ScheduleResult? _lastResult;

  bool _isReady = false;
  Timer? _persistDebounceTimer;

  bool get isReady => _isReady;
  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);
  UnmodifiableListView<DutyLocation> get locations =>
      UnmodifiableListView(_locations);
  DateTime get periodStart => _periodStart;
  DateTime get periodEnd => _periodEnd;
  List<ShiftWindow> get vardiyalar =>
      List<ShiftWindow>.unmodifiable(_vardiyalar);
  List<int> get seciliHaftaGunleri =>
      List<int>.unmodifiable(_seciliHaftaGunleri);
  int get minRestHours => _minRestHours;
  int get weeklyMaxShifts => _weeklyMaxShifts;
  ThemeMode get themeMode => _themeMode;
  ScheduleResult? get lastResult => _lastResult;

  List<Person> get aktifPeople =>
      _people.where((p) => p.aktifMi).toList(growable: false);

  Future<void> initialize() async {
    final PersistedState? loaded = await _storage.load();
    if (loaded == null) {
      _seedDefaults();
      await _persist();
    } else {
      _people
        ..clear()
        ..addAll(loaded.people);
      _locations
        ..clear()
        ..addAll(loaded.locations);
      _personSeq = loaded.personSeq;
      _locationSeq = loaded.locationSeq;
      _periodStart = loaded.periodStart;
      _periodEnd = loaded.periodEnd.isBefore(loaded.periodStart)
          ? loaded.periodStart
          : loaded.periodEnd;
      _vardiyalar = loaded.vardiyalar.isEmpty
          ? <ShiftWindow>[
              const ShiftWindow(
                id: 'default-1',
                start: TimeOfDay(hour: 8, minute: 0),
                end: TimeOfDay(hour: 20, minute: 0),
              ),
            ]
          : loaded.vardiyalar;
      _seciliHaftaGunleri = loaded.seciliHaftaGunleri;
      _minRestHours = loaded.minRestHours;
      _weeklyMaxShifts = loaded.weeklyMaxShifts;
      _themeMode = _themeModeFromStorage(loaded.themeMode);
      _lastResult = loaded.lastResult;
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> addPerson(String name) async {
    _people.add(Person(id: _personSeq++, adSoyad: name, aktifMi: true));
    await _persistAndNotify();
  }

  Future<void> togglePerson(int id, bool value) async {
    final int index = _people.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _people[index] = _people[index].copyWith(aktifMi: value);
    await _persistAndNotify();
  }

  Future<void> deletePerson(int id) async {
    _people.removeWhere((p) => p.id == id);
    await _persistAndNotify();
  }

  Future<void> addLocation(String ad, int kapasite) async {
    _locations.add(
      DutyLocation(id: _locationSeq++, ad: ad, kapasite: kapasite),
    );
    await _persistAndNotify();
  }

  Future<void> deleteLocation(int id) async {
    _locations.removeWhere((l) => l.id == id);
    await _persistAndNotify();
  }

  Future<void> setPeriodStart(DateTime value) async {
    _periodStart = DateTime(value.year, value.month, value.day);
    if (_periodEnd.isBefore(_periodStart)) {
      _periodEnd = _periodStart;
    }
    await _persistAndNotify();
  }

  Future<void> setPeriodEnd(DateTime value) async {
    final DateTime next = DateTime(value.year, value.month, value.day);
    _periodEnd = next.isBefore(_periodStart) ? _periodStart : next;
    await _persistAndNotify();
  }

  Future<void> addVardiya() async {
    _vardiyalar.add(
      ShiftWindow(
        id: 'v-${DateTime.now().microsecondsSinceEpoch}',
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 20, minute: 0),
      ),
    );
    await _persistAndNotify();
  }

  Future<void> removeVardiya(String id) async {
    if (_vardiyalar.length <= 1) return;
    _vardiyalar.removeWhere((v) => v.id == id);
    await _persistAndNotify();
  }

  Future<void> setVardiyaStart(String id, TimeOfDay value) async {
    final int index = _vardiyalar.indexWhere((v) => v.id == id);
    if (index == -1) return;
    _vardiyalar[index] = _vardiyalar[index].copyWith(start: value);
    await _persistAndNotify();
  }

  Future<void> setVardiyaEnd(String id, TimeOfDay value) async {
    final int index = _vardiyalar.indexWhere((v) => v.id == id);
    if (index == -1) return;
    _vardiyalar[index] = _vardiyalar[index].copyWith(end: value);
    await _persistAndNotify();
  }

  Future<void> setSeciliHaftaGunleri(List<int> gunler) async {
    _seciliHaftaGunleri = List<int>.from(gunler);
    await _persistAndNotify();
  }

  Future<void> setMinRestHours(int value) async {
    _minRestHours = value;
    _persistAndNotifyDebounced();
  }

  Future<void> setWeeklyMaxShifts(int value) async {
    _weeklyMaxShifts = value;
    _persistAndNotifyDebounced();
  }

  Future<void> toggleThemeMode() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await _persistAndNotify();
  }

  Future<void> generatePlan() async {
    if (_seciliHaftaGunleri.isEmpty) {
      _seciliHaftaGunleri = <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ];
    }

    final ScheduleRequest request = ScheduleRequest(
      baslangicTarihi: _periodStart,
      bitisTarihi: _periodEnd,
      seciliHaftaGunleri: _seciliHaftaGunleri,
      vardiyalar: _vardiyalar,
      kurallar: ScheduleRules(
        minDinlenmeSaat: _minRestHours,
        haftalikMaxNobet: _weeklyMaxShifts,
        esitlikYontemi: FairnessMethod.totalHours,
      ),
    );

    _lastResult = _scheduler.generate(
      people: _people,
      locations: _locations,
      request: request,
    );

    await _persistAndNotify();
  }

  Future<void> reassignAssignment(Assignment target, int newPersonId) async {
    final ScheduleResult? current = _lastResult;
    if (current == null) return;
    final int index = current.assignments.indexWhere(
      (a) => identical(a, target),
    );
    if (index == -1) return;

    current.assignments[index] = Assignment(
      tarih: target.tarih,
      locationId: target.locationId,
      shiftStart: target.shiftStart,
      shiftEnd: target.shiftEnd,
      durationHours: target.durationHours,
      personId: newPersonId,
    );
    current.assignments.sort((a, b) => a.shiftStart.compareTo(b.shiftStart));
    await _persistAndNotify();
  }

  Future<void> fillUnfilledSlot(UnfilledSlot slot, int personId) async {
    final ScheduleResult? current = _lastResult;
    if (current == null) return;
    final int index = current.unfilledSlots.indexWhere(
      (u) => identical(u, slot),
    );
    if (index == -1) return;

    final UnfilledSlot removed = current.unfilledSlots.removeAt(index);
    current.assignments.add(
      Assignment(
        tarih: DateTime(
          removed.shiftStart.year,
          removed.shiftStart.month,
          removed.shiftStart.day,
        ),
        locationId: removed.locationId,
        shiftStart: removed.shiftStart,
        shiftEnd: removed.shiftEnd,
        durationHours:
            removed.shiftEnd.difference(removed.shiftStart).inMinutes / 60,
        personId: personId,
      ),
    );
    current.assignments.sort((a, b) => a.shiftStart.compareTo(b.shiftStart));
    await _persistAndNotify();
  }

  bool hasCurrentPlanOverlap() {
    final ScheduleResult? existing = _lastResult;
    if (existing == null) return false;

    final DateTime newStart = _periodStart;
    final DateTime newEnd = _periodEnd;
    final DateTime oldStart = DateTime(
      existing.request.baslangicTarihi.year,
      existing.request.baslangicTarihi.month,
      existing.request.baslangicTarihi.day,
    );
    final DateTime oldEnd = DateTime(
      existing.request.bitisTarihi.year,
      existing.request.bitisTarihi.month,
      existing.request.bitisTarihi.day,
    );

    return !newEnd.isBefore(oldStart) && !newStart.isAfter(oldEnd);
  }

  Future<void> clearPlan() async {
    _lastResult = null;
    await _persistAndNotify();
  }

  int gerekenEkKisiSayisi() {
    final ScheduleResult? result = _lastResult;
    if (result == null || result.unfilledSlots.isEmpty) return 0;
    final int aktifKisi = _people.where((p) => p.aktifMi).length;
    final int toplamSlot =
        result.assignments.length + result.unfilledSlots.length;
    final int gunSayisi =
        result.request.bitisTarihi
            .difference(result.request.baslangicTarihi)
            .inDays +
        1;
    final int haftaSayisi = (gunSayisi / 7).ceil();
    final int kisiBasiMaxSlot = (haftaSayisi * _weeklyMaxShifts).clamp(
      1,
      100000,
    );
    final int gerekenToplamKisi = (toplamSlot / kisiBasiMaxSlot).ceil();
    final int eksik = gerekenToplamKisi - aktifKisi;
    return eksik > 0 ? eksik : 0;
  }

  void _seedDefaults() {
    _people
      ..clear()
      ..addAll(<Person>[
        Person(id: _personSeq++, adSoyad: 'Ayse Yilmaz', aktifMi: true),
        Person(id: _personSeq++, adSoyad: 'Mehmet Demir', aktifMi: true),
        Person(id: _personSeq++, adSoyad: 'Elif Kaya', aktifMi: true),
      ]);

    final DutyLocation acil = DutyLocation(
      id: _locationSeq++,
      ad: 'Acil',
      kapasite: 1,
    );
    _locations
      ..clear()
      ..add(acil);

    final DateTime now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, now.day);
    _periodEnd = _periodStart.add(const Duration(days: 6));
    _vardiyalar = <ShiftWindow>[
      const ShiftWindow(
        id: 'default-1',
        start: TimeOfDay(hour: 8, minute: 0),
        end: TimeOfDay(hour: 20, minute: 0),
      ),
    ];
    _seciliHaftaGunleri = <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];
    _minRestHours = 24;
    _weeklyMaxShifts = 2;
    _themeMode = ThemeMode.light;
    _lastResult = null;
  }

  Future<void> _persistAndNotify() async {
    _persistDebounceTimer?.cancel();
    await _persist();
    notifyListeners();
  }

  void _persistAndNotifyDebounced({
    Duration delay = const Duration(milliseconds: 350),
  }) {
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(delay, () async {
      await _persist();
      notifyListeners();
    });
  }

  Future<void> _persist() {
    return _storage.save(
      PersistedState(
        people: _people,
        locations: _locations,
        personSeq: _personSeq,
        locationSeq: _locationSeq,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        vardiyalar: _vardiyalar,
        seciliHaftaGunleri: _seciliHaftaGunleri,
        minRestHours: _minRestHours,
        weeklyMaxShifts: _weeklyMaxShifts,
        themeMode: _themeModeToStorage(_themeMode),
        lastResult: _lastResult,
      ),
    );
  }

  String _themeModeToStorage(ThemeMode mode) {
    return mode == ThemeMode.dark ? 'dark' : 'light';
  }

  ThemeMode _themeModeFromStorage(String value) {
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  void dispose() {
    _persistDebounceTimer?.cancel();
    super.dispose();
  }
}
