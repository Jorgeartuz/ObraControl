import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/features/material_entries/data/material_entry_repository.dart';
import 'create_material_entry_page.dart';

class MaterialEntriesListPage extends ConsumerWidget {
  final Project project;
  const MaterialEntriesListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(materialEntryRepositoryProvider).watchEntriesByProject(project.id);

    return Scaffold(
      appBar: AppBar(title: const Text("Entrada de materiales")),
      body: StreamBuilder<List<MaterialEntry>>(
        stream: entriesAsync,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) => _MaterialEntryCard(entry: entries[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CreateMaterialEntryPage(projectId: project.id))),
        label: const Text("Registrar entrada"),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text("Sin registros de entrada"),
        TextButton(onPressed: () {}, child: const Text("Registrar primera entrada")),
      ],
    ),
  );
}

class _MaterialEntryCard extends StatelessWidget {
  final MaterialEntry entry;
  const _MaterialEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Text(entry.syncStatus.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("${entry.quantity} ${entry.unit}", style: const TextStyle(fontSize: 18, color: Colors.amber)),
            const SizedBox(height: 8),
            Text(DateFormat('dd MMM yyyy · hh:mm a').format(entry.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (entry.supplier != null) Text("Origen: ${entry.supplier}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}