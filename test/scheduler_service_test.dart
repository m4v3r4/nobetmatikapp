import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nobetmatik/models/models.dart';
import 'package:nobetmatik/services/scheduler_service.dart';

void main() {
  group('SchedulerService fairness', () {
    test('esit bolunebilen slotlarda kisi basi nobet adedi esit olur', () {
      final SchedulerService scheduler = SchedulerService();
      final List<Person> people = <Person>[
        const Person(id: 1, adSoyad: 'A', aktifMi: true),
        const Person(id: 2, adSoyad: 'B', aktifMi: true),
        const Person(id: 3, adSoyad: 'C', aktifMi: true),
      ];
      final List<DutyLocation> locations = <DutyLocation>[
        const DutyLocation(id: 10, ad: 'Acil', kapasite: 1),
      ];
      final ScheduleRequest request = ScheduleRequest(
        baslangicTarihi: DateTime(2026, 1, 5),
        bitisTarihi: DateTime(2026, 1, 10),
        seciliHaftaGunleri: <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        vardiyalar: const <ShiftWindow>[
          ShiftWindow(
            id: 's-1',
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 20, minute: 0),
          ),
        ],
        kurallar: const ScheduleRules(
          minDinlenmeSaat: 0,
          haftalikMaxNobet: 7,
          esitlikYontemi: FairnessMethod.totalHours,
        ),
      );

      final ScheduleResult result = scheduler.generate(
        people: people,
        locations: locations,
        request: request,
      );

      final Map<int, int> counts = <int, int>{1: 0, 2: 0, 3: 0};
      for (final Assignment assignment in result.assignments) {
        counts[assignment.personId] = (counts[assignment.personId] ?? 0) + 1;
      }

      expect(result.unfilledSlots, isEmpty);
      expect(counts[1], 2);
      expect(counts[2], 2);
      expect(counts[3], 2);
    });

    test('bolunemeyen slotlarda fark en fazla bir olur', () {
      final SchedulerService scheduler = SchedulerService();
      final List<Person> people = <Person>[
        const Person(id: 1, adSoyad: 'A', aktifMi: true),
        const Person(id: 2, adSoyad: 'B', aktifMi: true),
        const Person(id: 3, adSoyad: 'C', aktifMi: true),
      ];
      final List<DutyLocation> locations = <DutyLocation>[
        const DutyLocation(id: 10, ad: 'Acil', kapasite: 1),
      ];
      final ScheduleRequest request = ScheduleRequest(
        baslangicTarihi: DateTime(2026, 1, 5),
        bitisTarihi: DateTime(2026, 1, 11),
        seciliHaftaGunleri: <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        vardiyalar: const <ShiftWindow>[
          ShiftWindow(
            id: 's-1',
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 20, minute: 0),
          ),
        ],
        kurallar: const ScheduleRules(
          minDinlenmeSaat: 0,
          haftalikMaxNobet: 7,
          esitlikYontemi: FairnessMethod.totalHours,
        ),
      );

      final ScheduleResult result = scheduler.generate(
        people: people,
        locations: locations,
        request: request,
      );

      final Map<int, int> counts = <int, int>{1: 0, 2: 0, 3: 0};
      for (final Assignment assignment in result.assignments) {
        counts[assignment.personId] = (counts[assignment.personId] ?? 0) + 1;
      }
      final List<int> sorted = counts.values.toList()..sort();

      expect(result.unfilledSlots, isEmpty);
      expect(sorted.last - sorted.first, lessThanOrEqualTo(1));
    });
  });
}
