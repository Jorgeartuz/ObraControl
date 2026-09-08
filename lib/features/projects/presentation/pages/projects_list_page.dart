import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/projects_provider.dart';
import 'create_project_page.dart';
import 'project_detail_page.dart';

class ProjectsListPage extends ConsumerWidget {
  const ProjectsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis obras', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: projectsAsync.when(
        data: (projects) => projects.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _ProjectCard(project: project);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateProjectPage()),
        ),
        label: const Text('Crear obra'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('¡Aún no tienes obras!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Comienza creando tu primera obra.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateProjectPage()),
            ),
            child: const Text('Crear mi primera obra'),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final dynamic project; // Usamos dynamic para evitar conflictos con Drift class
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.location != null && project.location!.isNotEmpty)
              Row(children: [const Icon(Icons.location_on, size: 14), Text(" ${project.location}")]),
            const SizedBox(height: 4),
            Text("Inicio: ${dateFormat.format(project.startDate)}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            project.status.toUpperCase(),
            style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project)),
        ),
      ),
    );
  }
}