import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_repository.dart';

class AddMachineryPage extends ConsumerStatefulWidget {
  final String projectId;
  final Machine? machine;
  const AddMachineryPage({super.key, required this.projectId, this.machine});

  bool get isEditing => machine != null;

  @override
  ConsumerState<AddMachineryPage> createState() => _AddMachineryPageState();
}

class _AddMachineryPageState extends ConsumerState<AddMachineryPage> {
  late final _nameController = TextEditingController(text: widget.machine?.name);
  late final _typeController = TextEditingController(text: widget.machine?.type);

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    final repository = ref.read(machineryRepositoryProvider);
    if (widget.isEditing) {
      final existing = widget.machine!;
      final updated = Machine(
        id: existing.id,
        projectId: existing.projectId,
        name: name,
        type: _typeController.text.isEmpty ? null : _typeController.text,
        description: existing.description,
        createdAt: existing.createdAt,
        createdBy: existing.createdBy,
        syncStatus: SyncStatus.pending,
      );
      await repository.updateMachine(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maquinaria actualizada correctamente")),
      );
    } else {
      final machine = Machine(
        id: const Uuid().v4(),
        projectId: widget.projectId,
        name: name,
        type: _typeController.text.isEmpty ? null : _typeController.text,
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await repository.addMachine(machine);
    }

    // PROTECCIÓN CONTRA ASYNC GAP (evita el error de flutter analyze)
    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Editar maquinaria" : "Agregar maquinaria"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre de la maquinaria *", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.engineering),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: "Tipo / Categoría", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text(
                  widget.isEditing ? "GUARDAR CAMBIOS" : "GUARDAR MAQUINARIA",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}