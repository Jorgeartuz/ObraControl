import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_repository.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_usage_repository.dart';
import 'add_machinery_usage_page.dart';

class MachineDetailPage extends ConsumerWidget {
  final Machine machine;
  const MachineDetailPage({super.key, required this.machine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineAsync = ref.watch(machineProvider(machine.id));

    return machineAsync.when(
      data: (currentMachine) {
        if (currentMachine == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Maquinaria")),
            body: const Center(child: Text("Esta maquinaria ya no existe.")),
          );
        }
        return _MachineDetailView(machine: currentMachine);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text("Maquinaria")),
        body: Center(child: Text("Error al cargar la maquinaria: $error")),
      ),
    );
  }
}

class _MachineDetailView extends ConsumerWidget {
  final Machine machine;
  const _MachineDetailView({required this.machine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(machineryUsageLogsProvider(machine.id));

    return Scaffold(
      appBar: AppBar(title: Text(machine.name)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blueGrey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.type ?? "Maquinaria de obra",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (machine.description != null && machine.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(machine.description!, style: const TextStyle(color: Colors.grey)),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.timelapse, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text("Historial de horómetro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timelapse_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text("Sin registros de uso todavía"),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amberAccent,
                          child: Icon(Icons.timelapse, color: Colors.black87),
                        ),
                        title: Text(DateFormat('dd/MM/yyyy').format(log.date)),
                        subtitle: Text(
                          "Inicial: ${log.horometerStart.toStringAsFixed(1)} h · Final: ${log.horometerEnd.toStringAsFixed(1)} h"
                          "${(log.observations?.isNotEmpty ?? false) ? '\n${log.observations}' : ''}",
                        ),
                        isThreeLine: log.observations?.isNotEmpty ?? false,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${log.hoursWorked.toStringAsFixed(2)} h",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Eliminar registro',
                              onPressed: () => _deleteLog(context, ref, log),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddMachineryUsagePage(machine: machine)),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Registrar uso"),
      ),
    );
  }

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    MachineryUsageLog log,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro de uso'),
        content: const Text('¿Seguro que deseas eliminar este registro de horómetro?'),
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
      await ref.read(machineryUsageRepositoryProvider).deleteUsageLog(log.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado correctamente.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el registro: $error')),
      );
    }
  }
}
