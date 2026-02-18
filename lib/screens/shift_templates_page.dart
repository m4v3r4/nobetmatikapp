import 'package:flutter/material.dart';

import '../models/duty_location.dart';
import '../models/shift_template.dart';
import '../utils/formatters.dart';

class ShiftTemplatesPage extends StatefulWidget {
  const ShiftTemplatesPage({
    super.key,
    required this.locations,
    required this.templates,
    required this.onAdd,
    required this.onDelete,
  });

  final List<DutyLocation> locations;
  final List<ShiftTemplate> templates;
  final void Function({
    required int locationId,
    required TimeOfDay baslangic,
    required TimeOfDay bitis,
  }) onAdd;
  final ValueChanged<int> onDelete;

  @override
  State<ShiftTemplatesPage> createState() => _ShiftTemplatesPageState();
}

class _ShiftTemplatesPageState extends State<ShiftTemplatesPage> {
  int? _selectedLocationId;
  TimeOfDay _start = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 8, minute: 0);

  @override
  void didUpdateWidget(covariant ShiftTemplatesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locations.isEmpty) {
      _selectedLocationId = null;
      return;
    }
    _selectedLocationId ??= widget.locations.first.id;
    if (!widget.locations.any((l) => l.id == _selectedLocationId)) {
      _selectedLocationId = widget.locations.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, DutyLocation> locationMap = {
      for (final loc in widget.locations) loc.id: loc,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          if (widget.locations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sablon eklemek icin once nobet yeri ekleyin.'),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    DropdownButtonFormField<int>(
                      initialValue: _selectedLocationId,
                      decoration: const InputDecoration(
                        labelText: 'Nobet Yeri',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.locations
                          .map(
                            (loc) => DropdownMenuItem<int>(
                              value: loc.id,
                              child: Text(loc.ad),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedLocationId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _start,
                              );
                              if (picked == null) return;
                              setState(() => _start = picked);
                            },
                            child: Text('Baslangic: ${formatTime(_start)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _end,
                              );
                              if (picked == null) return;
                              setState(() => _end = picked);
                            },
                            child: Text('Bitis: ${formatTime(_end)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _selectedLocationId == null
                            ? null
                            : () {
                                widget.onAdd(
                                  locationId: _selectedLocationId!,
                                  baslangic: _start,
                                  bitis: _end,
                                );
                              },
                        child: const Text('Sablon Ekle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.templates.length,
              itemBuilder: (context, index) {
                final ShiftTemplate t = widget.templates[index];
                final DutyLocation? loc = locationMap[t.locationId];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(loc?.ad ?? 'Bilinmeyen Yer'),
                    subtitle: Text(
                      '${formatTime(t.baslangicSaati)} - ${formatTime(t.bitisSaati)} | ${t.sureSaat.toStringAsFixed(1)} saat',
                    ),
                    trailing: IconButton(
                      onPressed: () => widget.onDelete(t.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
