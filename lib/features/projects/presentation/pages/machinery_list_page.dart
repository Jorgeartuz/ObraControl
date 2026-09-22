import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../machinery/data/machinery_repository.dart';
import '../../../machinery/presentation/pages/machine_detail_page.dart';
import 'add_machinery_page.dart';

class MachineryListPage extends ConsumerWidget {
  final Project project;
  const MachineryListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineryAsync = ref.watch(machineryStreamProvider(project.id));

    return Scaffold(
      appBar: AppBar(title: const Text("Registro de maquinaria")),
      body: machineryAsync.when(
        data: (machines) => machines.isEmpty 
          ? const Center(child: Text("No hay maquinaria registrada"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: machines.length,
              itemBuilder: (context, index) {
                final machine = machines[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.engineering, color: Colors.orange),
                    title: Text(machine.name),
                    subtitle: Text(machine.type ?? "Maquinaria de obra"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MachineDetailPage(machine: machine),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMachineryPage(
                                projectId: project.id,
                                machine: machine,
                              ),
                            ),
                          );
                        }
                        if (value == 'delete') {
                          _deleteMachine(context, ref, machine);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddMachineryPage(projectId: project.id))),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteMachine(
    BuildContext context,
    WidgetRef ref,
    Machine machine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar maquinaria'),
        content: Text('¿Seguro que deseas eliminar "${machine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(machineryRepositoryProvider).deleteMachine(machine.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maquinaria eliminada correctamente.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la maquinaria: $error')),
      );
    }
  }
}