import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/local_database.dart';

import 'package:obrafcontrol_test/features/projects/data/project_repository.dart';

class CreateProjectPage extends ConsumerStatefulWidget {
  const CreateProjectPage({super.key, this.project});

  final Project? project;

  @override
  ConsumerState<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends ConsumerState<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  DateTime _startDate = DateTime.now();
  String _status = 'activa';

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    if (project == null) return;

    _nameController.text = project.name;
    _descController.text = project.description ?? '';
    _locController.text = project.location ?? '';
    _startDate = project.startDate;
    _status = project.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final previousProject = widget.project;
    final project = Project(
      id: previousProject?.id ?? const Uuid().v4(),
      name: _nameController.text,
      description: _descController.text,
      location: _locController.text,
      startDate: _startDate,
      createdAt: previousProject?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      status: _status,
      createdBy: previousProject?.createdBy,
    );

    try {
      final repository = ref.read(projectRepositoryProvider);
      if (_isEditing) {
        await repository.updateProject(project);
      } else {
        await repository.createProject(project);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Obra actualizada correctamente.'
                : 'Obra creada correctamente.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la obra: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar obra' : 'Crear nueva obra'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la obra *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'activa', child: Text('Activa')),
                DropdownMenuItem(value: 'pausada', child: Text('Pausada')),
                DropdownMenuItem(
                  value: 'finalizada',
                  child: Text('Finalizada'),
                ),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Fecha de inicio"),
              subtitle: Text(
                "${_startDate.day}/${_startDate.month}/${_startDate.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              tileColor: Colors.blueGrey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR OBRA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
