import 'package:flutter/material.dart';

import '../models/person.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({
    super.key,
    required this.people,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<Person> people;
  final ValueChanged<String> onAdd;
  final void Function(int id, bool value) onToggle;
  final ValueChanged<int> onDelete;

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final String name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  widget.onAdd(name);
                  _nameController.clear();
                },
                child: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.people.length,
              itemBuilder: (context, index) {
                final Person person = widget.people[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(person.adSoyad),
                    subtitle: Text('ID: ${person.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Switch(
                          value: person.aktifMi,
                          onChanged: (value) => widget.onToggle(person.id, value),
                        ),
                        IconButton(
                          onPressed: () => widget.onDelete(person.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
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
