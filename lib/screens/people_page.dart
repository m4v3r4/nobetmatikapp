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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 700;
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
                      itemCount: widget.people.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final Person person = widget.people[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(person.adSoyad),
                            subtitle: Text('ID: ${person.id}'),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                children: <Widget>[
                                  Switch(
                                    value: person.aktifMi,
                                    onChanged: (value) =>
                                        widget.onToggle(person.id, value),
                                  ),
                                  IconButton(
                                    onPressed: () => widget.onDelete(person.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
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
            decoration: const InputDecoration(labelText: 'Ad Soyad'),
            onSubmitted: (_) => _submit(),
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
          decoration: const InputDecoration(labelText: 'Ad Soyad'),
          onSubmitted: (_) => _submit(),
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
    if (name.isEmpty) return;
    widget.onAdd(name);
    _nameController.clear();
  }
}
