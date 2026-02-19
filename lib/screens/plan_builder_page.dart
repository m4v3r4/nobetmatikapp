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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 940;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: wide
                          ? Row(
                              children: <Widget>[
                                Expanded(child: _periodStartButton(context)),
                                const SizedBox(width: 10),
                                Expanded(child: _periodEndButton(context)),
                              ],
                            )
                          : Column(
                              children: <Widget>[
                                _periodStartButton(context),
                                const SizedBox(height: 10),
                                _periodEndButton(context),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Vardiyalar',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: onAddVardiya,
                                icon: const Icon(Icons.add),
                                label: const Text('Vardiya Ekle'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...vardiyalar.map((v) => _shiftCard(context, v)),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 12),
                          wide
                              ? Row(
                                  children: <Widget>[
                                    Expanded(child: _minRestField()),
                                    const SizedBox(width: 10),
                                    Expanded(child: _weeklyMaxField()),
                                  ],
                                )
                              : Column(
                                  children: <Widget>[
                                    _minRestField(),
                                    const SizedBox(height: 10),
                                    _weeklyMaxField(),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
            ),
          ),
        );
      },
    );
  }

  Widget _periodStartButton(BuildContext context) {
    return OutlinedButton(
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
    );
  }

  Widget _periodEndButton(BuildContext context) {
    return OutlinedButton(
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
    );
  }

  Widget _shiftCard(BuildContext context, ShiftWindow v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;
            if (wide) {
              return Row(
                children: <Widget>[
                  Expanded(child: _shiftStartButton(context, v)),
                  const SizedBox(width: 8),
                  Expanded(child: _shiftEndButton(context, v)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onRemoveVardiya(v.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              );
            }

            return Column(
              children: <Widget>[
                _shiftStartButton(context, v),
                const SizedBox(height: 8),
                _shiftEndButton(context, v),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => onRemoveVardiya(v.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _shiftStartButton(BuildContext context, ShiftWindow v) {
    return OutlinedButton(
      onPressed: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: v.start,
        );
        if (picked != null) {
          onSetVardiyaStart(v.id, picked);
        }
      },
      child: Text('Baslangic: ${formatTime(v.start)}'),
    );
  }

  Widget _shiftEndButton(BuildContext context, ShiftWindow v) {
    return OutlinedButton(
      onPressed: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: v.end,
        );
        if (picked != null) {
          onSetVardiyaEnd(v.id, picked);
        }
      },
      child: Text('Bitis: ${formatTime(v.end)}'),
    );
  }

  Widget _minRestField() {
    return TextFormField(
      initialValue: minRestHours.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Min Dinlenme (saat)'),
      onChanged: (value) {
        final int parsed = int.tryParse(value) ?? 24;
        onMinRestChanged(parsed < 0 ? 0 : parsed);
      },
    );
  }

  Widget _weeklyMaxField() {
    return TextFormField(
      initialValue: weeklyMaxShifts.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Haftalik Max Nobet (kisi basi)',
      ),
      onChanged: (value) {
        final int parsed = int.tryParse(value) ?? 2;
        onWeeklyMaxChanged(parsed < 1 ? 1 : parsed);
      },
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
