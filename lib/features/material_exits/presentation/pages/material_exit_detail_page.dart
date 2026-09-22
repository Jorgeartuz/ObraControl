import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/status_badge.dart';
import 'package:obrafcontrol_test/features/material_exits/data/material_exit_repository.dart';
import 'create_material_exit_page.dart';

class MaterialExitDetailPage extends ConsumerWidget {
  final MaterialExit exit;
  const MaterialExitDetailPage({super.key, required this.exit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exitAsync = ref.watch(materialExitProvider(exit.id));

    return exitAsync.when(
      data: (currentExit) {
        if (currentExit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Detalle de salida")),
            body: const Center(child: Text("Esta salida ya no existe.")),
          );
        }
        return _MaterialExitDetailView(exit: currentExit);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text("Detalle de salida")),
        body: Center(child: Text("Error al cargar la salida: $error")),
      ),
    );
  }
}

class _MaterialExitDetailView extends ConsumerWidget {
  final MaterialExit exit;
  const _MaterialExitDetailView({required this.exit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de salida"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar salida',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateMaterialExitPage(
                  projectId: exit.projectId,
                  exit: exit,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar salida',
            onPressed: () => _deleteExit(context, ref, exit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildField("Material", exit.materialName),
          _buildField("Cantidad", "${exit.quantity} ${exit.unit}"),
          _buildField("Fecha", DateFormat('dd/MM/yyyy').format(exit.date)),
          _buildField("Hora", DateFormat('HH:mm').format(exit.date)),
          _buildField("Destino", exit.destination),
          if (exit.responsible != null) _buildField("Responsable", exit.responsible!),
          if (exit.observations != null) _buildField("Observaciones", exit.observations!),
          const SizedBox(height: 20),
          const Text("Estado de sincronización", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StatusBadge(status: exit.syncStatus),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Future<void> _deleteExit(
    BuildContext context,
    WidgetRef ref,
    MaterialExit exit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar salida'),
        content: Text('¿Seguro que deseas eliminar la salida de "${exit.materialName}"?'),
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
      await ref.read(materialExitRepositoryProvider).deleteExit(exit.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salida eliminada correctamente.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la salida: $error')),
      );
    }
  }
}
