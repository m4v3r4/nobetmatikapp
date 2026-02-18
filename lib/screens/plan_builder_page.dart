import 'package:flutter/material.dart';

import '../models/shift_window.dart';
import '../utils/formatters.dart';

class PlanBuilderPage extends StatelessWidget {
  const PlanBuilderPage({
    super.key,
    required this.periodStart,
    required this.periodEnd,
    required this.vardiyalar,
    required this.seciliHaftaGunleri,
    required this.minRestHours,
    required this.weeklyMaxShifts,
    required this.onPeriodStartChanged,
    required this.onPeriodEndChanged,
    required this.onAddVardiya,
    required this.onRemoveVardiya,
    required this.onSetVardiyaStart,
    required this.onSetVardiyaEnd,
    required this.onSeciliHaftaGunleriChanged,
    required this.onMinRestChanged,
    required this.onWeeklyMaxChanged,
    required this.onGenerate,
    required this.isGenerating,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ShiftWindow> vardiyalar;
  final List<int> seciliHaftaGunleri;
  final int minRestHours;
  final int weeklyMaxShifts;
  final ValueChanged<DateTime> onPeriodStartChanged;
  final ValueChanged<DateTime> onPeriodEndChanged;
  final VoidCallback onAddVardiya;
  final ValueChanged<String> onRemoveVardiya;
  final void Function(String id, TimeOfDay value) onSetVardiyaStart;
  final void Function(String id, TimeOfDay value) onSetVardiyaEnd;
  final ValueChanged<List<int>> onSeciliHaftaGunleriChanged;
  final ValueChanged<int> onMinRestChanged;
  final ValueChanged<int> onWeeklyMaxChanged;
  final VoidCallback onGenerate;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: <Widget>[
          OutlinedButton(
            onPressed: () async {
              final DateTime now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
                initialDate: periodStart,
              );
              if (picked != null) onPeriodStartChanged(picked);
            },
            child: Text('Baslangic Tarihi: ${formatDate(periodStart)}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final DateTime now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
                initialDate: periodEnd.isBefore(periodStart)
                    ? periodStart
                    : periodEnd,
              );
              if (picked != null) onPeriodEndChanged(picked);
            },
            child: Text('Bitis Tarihi: ${formatDate(periodEnd)}'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Vardiyalar')),
                      OutlinedButton.icon(
                        onPressed: onAddVardiya,
                        icon: const Icon(Icons.add),
                        label: const Text('Vardiya Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...vardiyalar.map(
                    (v) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: v.start,
                                      );
                                  if (picked != null) {
                                    onSetVardiyaStart(v.id, picked);
                                  }
                                },
                                child: Text(
                                  'Baslangic: ${formatTime(v.start)}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: v.end,
                                      );
                                  if (picked != null) {
                                    onSetVardiyaEnd(v.id, picked);
                                  }
                                },
                                child: Text('Bitis: ${formatTime(v.end)}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => onRemoveVardiya(v.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Nobet gunleri'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _weekdayChip(DateTime.monday, 'Pzt'),
                      _weekdayChip(DateTime.tuesday, 'Sal'),
                      _weekdayChip(DateTime.wednesday, 'Car'),
                      _weekdayChip(DateTime.thursday, 'Per'),
                      _weekdayChip(DateTime.friday, 'Cum'),
                      _weekdayChip(DateTime.saturday, 'Cmt'),
                      _weekdayChip(DateTime.sunday, 'Paz'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: minRestHours.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Dinlenme (saat)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final int parsed = int.tryParse(value) ?? 24;
                      onMinRestChanged(parsed < 0 ? 0 : parsed);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: weeklyMaxShifts.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Haftalik Max Nobet (kisi basi)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final int parsed = int.tryParse(value) ?? 2;
                      onWeeklyMaxChanged(parsed < 1 ? 1 : parsed);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isGenerating ? null : onGenerate,
            icon: isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(isGenerating ? 'Uretiliyor...' : 'Plan Uret'),
          ),
        ],
      ),
    );
  }

  Widget _weekdayChip(int day, String label) {
    final bool selected = seciliHaftaGunleri.contains(day);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        final List<int> next = List<int>.from(seciliHaftaGunleri);
        if (value) {
          if (!next.contains(day)) next.add(day);
        } else {
          if (next.length <= 1) return;
          next.remove(day);
        }
        next.sort();
        onSeciliHaftaGunleriChanged(next);
      },
    );
  }
}
