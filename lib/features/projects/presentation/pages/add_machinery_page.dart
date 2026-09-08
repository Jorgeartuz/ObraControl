import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_repository.dart';


class AddMachineryPage extends ConsumerStatefulWidget {
  final String projectId;
  const AddMachineryPage({super.key, required this.projectId});

  @override
  ConsumerState<AddMachineryPage> createState() => _AddMachineryPageState();
}

class _AddMachineryPageState extends ConsumerState<AddMachineryPage> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar maquinaria")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre (ej. Minicargador)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: "Tipo/Categoría"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final machine = Machine(
                  id: const Uuid().v4(),
                  projectId: widget.projectId,
                  name: _nameController.text,
                  type: _typeController.text,
                  createdAt: DateTime.now(),
                  syncStatus: SyncStatus.pending,
                );
                await ref.read(machineryRepositoryProvider).addMachine(machine);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Guardar maquinaria"),
            )
          ],
        ),
      ),
    );
  }
}