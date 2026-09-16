import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/app_card.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/app_empty_state.dart';
import 'package:obrafcontrol_test/features/projects/presentation/providers/projects_provider.dart';
import 'package:obrafcontrol_test/features/auth/data/auth_repository.dart'; // Import necesario

import 'create_project_page.dart';
import 'project_detail_page.dart';

class ProjectsListPage extends ConsumerWidget {
  const ProjectsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis obras'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) => projects.isEmpty
            ? AppEmptyState(
                title: "No hay obras registradas",
                message:
                    "Comienza a gestionar tu primera obra de construcción.",
                icon: Icons.architecture,
                buttonLabel: "Crear primera obra",
                onButtonPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateProjectPage()),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) =>
                    _ProjectCard(project: projects[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateProjectPage()),
        ),
        label: const Text('Nueva obra'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No se pudo cerrar sesión. Inténtalo nuevamente.")),
                );
              }
            },
            child: const Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: project.location ?? "Ubicación no especificada",
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text:
                "Inicio: ${DateFormat('dd MMM yyyy').format(project.startDate)}",
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    ],
  );
}
