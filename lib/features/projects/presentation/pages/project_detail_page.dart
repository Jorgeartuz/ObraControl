import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/module_card.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/section_header.dart';

import 'daily_records_list_page.dart';

import 'package:obrafcontrol_test/features/material_entries/presentation/pages/material_entries_list_page.dart';
import 'package:obrafcontrol_test/features/material_exits/presentation/pages/material_exits_list_page.dart';
import 'package:obrafcontrol_test/features/dump_trucks/presentation/pages/dump_trucks_list_page.dart';
import 'package:obrafcontrol_test/features/dashboard/presentation/widgets/dashboard_indicators_grid.dart';
import 'package:obrafcontrol_test/features/dashboard/presentation/widgets/dashboard_activity_list.dart';

import 'machinery_list_page.dart';
import 'create_project_page.dart';
import '../providers/projects_provider.dart';
import '../../data/project_repository.dart';

class ProjectDetailPage extends ConsumerWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectStreamProvider(project.id));

    return projectAsync.when(
      data: (currentProject) {
        if (currentProject == null) {
          return const Scaffold(
            body: Center(child: Text('La obra ya no está disponible.')),
          );
        }

        final project = currentProject;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar obra',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateProjectPage(project: project),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar obra',
                onPressed: () => _deleteProject(context, ref, project),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProjectHeader(),
                      const SectionHeader(title: "Indicadores"),
                      DashboardIndicatorsGrid(projectId: project.id),
                      const SectionHeader(title: "Actividad reciente"),
                      DashboardActivityList(projectId: project.id),
                      const SectionHeader(title: "Módulos de Control"),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                        children: [
                          ModuleCard(
                            title: "Actividades",
                            subtitle: "Registro fotográfico",
                            icon: Icons.camera_alt_outlined,
                            variant: ModuleCardVariant.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DailyRecordsListPage(project: project),
                              ),
                            ),
                          ),
                          ModuleCard(
                            title: "Entradas",
                            subtitle: "Ingreso de material",
                            icon: Icons.input_rounded,
                            variant: ModuleCardVariant.success,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MaterialEntriesListPage(project: project),
                              ),
                            ),
                          ),
                          ModuleCard(
                            title: "Salidas",
                            subtitle: "Retiro de material",
                            icon: Icons.output_rounded,
                            variant: ModuleCardVariant.error,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MaterialExitsListPage(project: project),
                              ),
                            ),
                          ),
                          ModuleCard(
                            title: "Maquinaria",
                            subtitle: "Control de equipo",
                            icon: Icons.engineering_outlined,
                            variant: ModuleCardVariant.warning,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MachineryListPage(project: project),
                              ),
                            ),
                          ),
                          ModuleCard(
                            title: "Volquetas",
                            subtitle: "Entrada y salida",
                            icon: Icons.local_shipping_outlined,
                            variant: ModuleCardVariant.info,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DumpTrucksListPage(project: project),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('No se pudo cargar la obra: $error')),
      ),
    );
  }

  Future<void> _deleteProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar obra'),
        content: Text('¿Seguro que deseas eliminar "${project.name}"?'),
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
      await ref.read(projectRepositoryProvider).deleteProject(project.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obra eliminada correctamente.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la obra: $error')),
      );
    }
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.location ?? "Ubicación no especificada",
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.description ?? "Sin descripción",
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
