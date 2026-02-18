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
  final TextEditingController _capacityController =
      TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nobet Yeri Adi',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: TextField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kapasite',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final String name = _nameController.text.trim();
                  final int kapasite = int.tryParse(_capacityController.text) ?? 1;
                  if (name.isEmpty || kapasite < 1) return;
                  widget.onAdd(name, kapasite);
                  _nameController.clear();
                  _capacityController.text = '1';
                },
                child: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.locations.length,
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
    );
  }
}
