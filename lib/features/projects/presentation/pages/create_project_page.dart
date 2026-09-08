import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/sync/data/project_repository.dart';

class CreateProjectPage extends ConsumerStatefulWidget {
  const CreateProjectPage({super.key});

  @override
  ConsumerState<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends ConsumerState<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  DateTime _startDate = DateTime.now();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final project = Project(
      id: const Uuid().v4(),
      name: _nameController.text,
      description: _descController.text,
      location: _locController.text,
      startDate: _startDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'activa',
    );

    await ref.read(projectRepositoryProvider).createProject(project);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear nueva obra')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la obra *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locController,
              decoration: const InputDecoration(labelText: 'Ubicación', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Fecha de inicio"),
              subtitle: Text("${_startDate.day}/${_startDate.month}/${_startDate.year}"),
              trailing: const Icon(Icons.calendar_today),
              tileColor: Colors.blueGrey[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('CREAR OBRA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}