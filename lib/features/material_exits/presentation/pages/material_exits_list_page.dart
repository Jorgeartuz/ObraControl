import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/status_badge.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/features/material_exits/data/material_exit_repository.dart';
import 'create_material_exit_page.dart';

class MaterialExitsListPage extends ConsumerWidget {
  final Project project;
  
  const MaterialExitsListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(materialExitStreamProvider(project.id));

    return Scaffold(
      appBar: AppBar(title: const Text("Salida de material")),
      body: entriesAsync.when(
        data: (exits) => exits.isEmpty 
            ? _buildEmptyState(context) 
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exits.length,
                itemBuilder: (context, index) => MaterialExitCard(exit: exits[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CreateMaterialExitPage(projectId: project.id))),
        label: const Text("Registrar salida"),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text("Sin registros de salida"),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CreateMaterialExitPage(projectId: project.id))),
          child: const Text("Registrar primera salida"),
        ),
      ],
    ),
  );
}

class MaterialExitCard extends StatelessWidget {
  final MaterialExit exit;
  const MaterialExitCard({super.key, required this.exit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(exit.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                StatusBadge(status: exit.syncStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${exit.quantity} ${exit.unit}", 
              style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text("Destino: ${exit.destination}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy · hh:mm a').format(exit.date), 
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)
            ),
          ],
        ),
      ),
    );
  }
}