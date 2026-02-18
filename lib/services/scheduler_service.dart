import '../models/models.dart';

class _ShiftSlot {
  const _ShiftSlot({
    required this.locationId,
    required this.start,
    required this.end,
    required this.durationHours,
  });

  final int locationId;
  final DateTime start;
  final DateTime end;
  final double durationHours;
}

class _CandidateEval {
  const _CandidateEval({required this.uygun, required this.skor});

  final bool uygun;
  final double skor;
}

class SchedulerService {
  ScheduleResult generate({
    required List<Person> people,
    required List<DutyLocation> locations,
    required ScheduleRequest request,
  }) {
    final List<Person> aktifKisiler = people.where((p) => p.aktifMi).toList();
    final List<_ShiftSlot> tumSlotlar = _buildSlots(
      locations: locations,
      baslangic: request.baslangicTarihi,
      bitis: request.bitisTarihi,
      seciliHaftaGunleri: request.seciliHaftaGunleri,
      vardiyalar: request.vardiyalar,
    );

    if (aktifKisiler.isEmpty || tumSlotlar.isEmpty) {
      return ScheduleResult(
        request: request,
        assignments: const <Assignment>[],
        unfilledSlots: tumSlotlar
            .map(
              (slot) => UnfilledSlot(
                locationId: slot.locationId,
                shiftStart: slot.start,
                shiftEnd: slot.end,
                reason: aktifKisiler.isEmpty
                    ? 'Aktif kisi yok.'
                    : 'Planlanacak slot yok.',
              ),
            )
            .toList(),
        targetHours: 0,
      );
    }

    final double toplamSaat = tumSlotlar.fold(
      0,
      (sum, slot) => sum + slot.durationHours,
    );
    final double hedefSaat = toplamSaat / aktifKisiler.length;

    final Map<int, double> kisiSaat = {
      for (final person in aktifKisiler) person.id: 0,
    };
    final Map<int, int> kisiNobetAdedi = {
      for (final person in aktifKisiler) person.id: 0,
    };
    final Map<int, DateTime?> kisiSonNobetBitis = {
      for (final person in aktifKisiler) person.id: null,
    };
    final Map<int, List<Assignment>> kisiAtamalari = {
      for (final person in aktifKisiler) person.id: <Assignment>[],
    };

    final List<Assignment> assignments = <Assignment>[];
    final List<UnfilledSlot> unfilled = <UnfilledSlot>[];

    for (final _ShiftSlot slot in tumSlotlar) {
      Person? enIyi;
      double enIyiSkor = double.infinity;

      for (final Person person in aktifKisiler) {
        final _CandidateEval deger = _scoreCandidate(
          person: person,
          slot: slot,
          hedefSaat: hedefSaat,
          rules: request.kurallar,
          kisiSaat: kisiSaat,
          kisiNobetAdedi: kisiNobetAdedi,
          kisiSonNobetBitis: kisiSonNobetBitis,
          kisiAtamalari: kisiAtamalari,
        );

        if (!deger.uygun) {
          continue;
        }

        if (deger.skor < enIyiSkor) {
          enIyiSkor = deger.skor;
          enIyi = person;
        }
      }

      if (enIyi == null) {
        unfilled.add(
          UnfilledSlot(
            locationId: slot.locationId,
            shiftStart: slot.start,
            shiftEnd: slot.end,
            reason: 'Kurallar nedeniyle uygun kisi bulunamadi.',
          ),
        );
        continue;
      }

      final Assignment atama = Assignment(
        tarih: DateTime(slot.start.year, slot.start.month, slot.start.day),
        locationId: slot.locationId,
        shiftStart: slot.start,
        shiftEnd: slot.end,
        durationHours: slot.durationHours,
        personId: enIyi.id,
      );

      assignments.add(atama);
      kisiAtamalari[enIyi.id]!.add(atama);
      kisiSaat[enIyi.id] = (kisiSaat[enIyi.id] ?? 0) + slot.durationHours;
      kisiNobetAdedi[enIyi.id] = (kisiNobetAdedi[enIyi.id] ?? 0) + 1;
      kisiSonNobetBitis[enIyi.id] = slot.end;
    }

    assignments.sort((a, b) => a.shiftStart.compareTo(b.shiftStart));

    return ScheduleResult(
      request: request,
      assignments: assignments,
      unfilledSlots: unfilled,
      targetHours: hedefSaat,
    );
  }

  List<_ShiftSlot> _buildSlots({
    required List<DutyLocation> locations,
    required DateTime baslangic,
    required DateTime bitis,
    required List<int> seciliHaftaGunleri,
    required List<ShiftWindow> vardiyalar,
  }) {
    final DateTime startDate = DateTime(
      baslangic.year,
      baslangic.month,
      baslangic.day,
    );
    final DateTime endDate = DateTime(bitis.year, bitis.month, bitis.day);

    final List<_ShiftSlot> slots = <_ShiftSlot>[];

    for (
      DateTime day = startDate;
      !day.isAfter(endDate);
      day = day.add(const Duration(days: 1))
    ) {
      if (!seciliHaftaGunleri.contains(day.weekday)) {
        continue;
      }
      for (final DutyLocation location in locations) {
        for (final ShiftWindow vardiya in vardiyalar) {
          final DateTime start = DateTime(
            day.year,
            day.month,
            day.day,
            vardiya.start.hour,
            vardiya.start.minute,
          );
          DateTime end = DateTime(
            day.year,
            day.month,
            day.day,
            vardiya.end.hour,
            vardiya.end.minute,
          );
          if (!end.isAfter(start)) {
            end = end.add(const Duration(days: 1));
          }

          for (int i = 0; i < location.kapasite; i++) {
            slots.add(
              _ShiftSlot(
                locationId: location.id,
                start: start,
                end: end,
                durationHours: end.difference(start).inMinutes / 60,
              ),
            );
          }
        }
      }
    }

    slots.sort((a, b) => a.start.compareTo(b.start));
    return slots;
  }

  _CandidateEval _scoreCandidate({
    required Person person,
    required _ShiftSlot slot,
    required double hedefSaat,
    required ScheduleRules rules,
    required Map<int, double> kisiSaat,
    required Map<int, int> kisiNobetAdedi,
    required Map<int, DateTime?> kisiSonNobetBitis,
    required Map<int, List<Assignment>> kisiAtamalari,
  }) {
    final List<Assignment> existing = kisiAtamalari[person.id] ?? <Assignment>[];

    final bool cakismaVar = existing.any(
      (a) => a.shiftStart.isBefore(slot.end) && slot.start.isBefore(a.shiftEnd),
    );
    if (cakismaVar) {
      return const _CandidateEval(uygun: false, skor: double.infinity);
    }

    final DateTime? sonBitis = kisiSonNobetBitis[person.id];
    if (sonBitis != null) {
      final int dinlenmeSaat = slot.start.difference(sonBitis).inHours;
      if (dinlenmeSaat < rules.minDinlenmeSaat) {
        return const _CandidateEval(uygun: false, skor: double.infinity);
      }
    }

    final int haftaNobetSayisi = _weekShiftCount(existing, slot.start);
    if (haftaNobetSayisi >= rules.haftalikMaxNobet) {
      return const _CandidateEval(uygun: false, skor: double.infinity);
    }

    final double mevcutSaat = kisiSaat[person.id] ?? 0;
    final double projectedSaat = mevcutSaat + slot.durationHours;
    final double dengeSkoru = (projectedSaat - hedefSaat).abs() * 10;
    final double adetSkoru = (kisiNobetAdedi[person.id] ?? 0) * 3;

    double yakinlikCeza = 0;
    if (sonBitis != null) {
      final int saatFarki = slot.start.difference(sonBitis).inHours;
      if (saatFarki < 72) {
        yakinlikCeza = (72 - saatFarki).toDouble();
      }
    }

    return _CandidateEval(
      uygun: true,
      skor: dengeSkoru + adetSkoru + yakinlikCeza,
    );
  }

  int _weekShiftCount(List<Assignment> assignments, DateTime date) {
    final int weekKey = _weekKey(date);
    return assignments.where((a) => _weekKey(a.shiftStart) == weekKey).length;
  }

  int _weekKey(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final DateTime weekStart = normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
    return weekStart.year * 1000 + _dayOfYear(weekStart);
  }

  int _dayOfYear(DateTime d) {
    final DateTime first = DateTime(d.year, 1, 1);
    return d.difference(first).inDays + 1;
  }
}
