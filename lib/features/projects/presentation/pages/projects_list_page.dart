import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/app_card.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/app_empty_state.dart';
import 'package:obrafcontrol_test/features/projects/presentation/providers/projects_provider.dart';
import 'package:obrafcontrol_test/features/auth/data/auth_repository.dart';
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
                title: "No hay obras",
                message: "Comienza a gestionar tu primera obra de construcción.",
                icon: Icons.architecture,
                buttonLabel: "Crear primera obra",
                onButtonPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectPage())),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) => _ProjectCard(project: projects[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Centra el botón abajo
floatingActionButton: SizedBox(
  height: 56,
  width: MediaQuery.of(context).size.width * 0.9, // Ancho casi total
  child: FloatingActionButton.extended(
    onPressed: () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CreateProjectPage())
    ),
    backgroundColor: AppColors.actionButton,
    foregroundColor: Colors.white,
    elevation: 4,
    label: const Text(
      "Nueva obra", 
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
    ),
    icon: const Icon(Icons.add),
  ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text("Cerrar sesión", style: TextStyle(color: AppColors.error)),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
              ),
              _buildStatusPill(project.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.location_on_outlined, text: project.location ?? "Ubicación no especificada"),
          _InfoRow(icon: Icons.calendar_today_outlined, text: "Inicio: ${DateFormat('yyyy-MM-dd').format(project.startDate)}"),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project))),
                child: const Row(
                  children: [
                    Text("Ver detalle", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info)),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    ),
  );
}