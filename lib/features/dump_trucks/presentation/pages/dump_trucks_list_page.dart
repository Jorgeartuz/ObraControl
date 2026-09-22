import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/status_badge.dart';
import 'package:obrafcontrol_test/features/dump_trucks/data/dump_truck_repository.dart';
import 'create_dump_truck_page.dart';

class DumpTrucksListPage extends ConsumerWidget {
  final Project project;
  const DumpTrucksListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dumpTruckLogsProvider(project.id));

    return Scaffold(
      appBar: AppBar(title: const Text("Control de volquetas")),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) => _DumpTruckCard(
                  log: logs[index],
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateDumpTruckPage(
                        projectId: project.id,
                        log: logs[index],
                      ),
                    ),
                  ),
                  onRegisterExit: () => _registerExit(context, ref, logs[index]),
                  onDelete: () => _deleteLog(context, ref, logs[index]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateDumpTruckPage(projectId: project.id),
          ),
        ),
        label: const Text("Registrar entrada"),
        icon: const Icon(Icons.local_shipping_outlined),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text("No hay volquetas registradas"),
        const SizedBox(height: 8),
        const Text("Toca 'Registrar entrada' para comenzar."),
      ],
    ),
  );

  Future<void> _registerExit(
    BuildContext context,
    WidgetRef ref,
    DumpTruckLog log,
  ) async {
    var exitTime = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Registrar salida — ${log.plate}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entrada: ${DateFormat('dd/MM/yyyy - HH:mm').format(log.entryTime)}'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hora de salida'),
                subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(exitTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: exitTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date == null) return;
                  if (!dialogContext.mounted) return;
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay.fromDateTime(exitTime),
                  );
                  if (time == null) return;
                  setDialogState(() {
                    exitTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Registrar salida'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(dumpTruckRepositoryProvider).registerExit(log.id, exitTime);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salida registrada correctamente.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar la salida: $error')),
      );
    }
  }

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    DumpTruckLog log,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Seguro que deseas eliminar el registro de la placa "${log.plate}"?'),
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
      await ref.read(dumpTruckRepositoryProvider).deleteLog(log.id);
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

class _DumpTruckCard extends StatelessWidget {
  final DumpTruckLog log;
  final VoidCallback onEdit;
  final VoidCallback onRegisterExit;
  final VoidCallback onDelete;

  const _DumpTruckCard({
    required this.log,
    required this.onEdit,
    required this.onRegisterExit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pending = log.exitTime == null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.plate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                StatusBadge(status: log.syncStatus),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'exit') onRegisterExit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (pending)
                      const PopupMenuItem(value: 'exit', child: Text('Registrar salida')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("${log.material} · ${log.quantity} ${log.unit}", style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text("Conductor: ${log.driver}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.login, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  "Entrada: ${DateFormat('dd/MM/yyyy HH:mm').format(log.entryTime)}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.logout, size: 14, color: pending ? Colors.orange : Colors.red),
                const SizedBox(width: 4),
                Text(
                  pending ? "Salida: pendiente" : "Salida: ${DateFormat('dd/MM/yyyy HH:mm').format(log.exitTime!)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: pending ? FontWeight.bold : FontWeight.normal,
                    color: pending ? Colors.orange[800] : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
