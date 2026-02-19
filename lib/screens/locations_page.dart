import 'package:flutter/material.dart';

import '../models/duty_location.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({
    super.key,
    required this.locations,
    required this.onAdd,
    required this.onDelete,
  });

  final List<DutyLocation> locations;
  final void Function(String ad, int kapasite) onAdd;
  final ValueChanged<int> onDelete;

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: compact ? _buildCompactForm() : _buildWideForm(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: widget.locations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final DutyLocation loc = widget.locations[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(loc.ad),
                            subtitle: Text('Kapasite: ${loc.kapasite}'),
                            trailing: IconButton(
                              onPressed: () => widget.onDelete(loc.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideForm() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nobet Yeri Adi'),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: TextField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kapasite'),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Ekle'),
        ),
      ],
    );
  }

  Widget _buildCompactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nobet Yeri Adi'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Kapasite'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Ekle'),
        ),
      ],
    );
  }

  void _submit() {
    final String name = _nameController.text.trim();
    final int kapasite = int.tryParse(_capacityController.text) ?? 1;
    if (name.isEmpty || kapasite < 1) return;
    widget.onAdd(name, kapasite);
    _nameController.clear();
    _capacityController.text = '1';
  }
}
