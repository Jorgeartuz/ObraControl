import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import '../../../machinery/data/machinery_repository.dart';
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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Aquí se abrirá el detalle de la maquinaria en el futuro
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Abriendo: ${machine.name}"))
                      );
                    },
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
}