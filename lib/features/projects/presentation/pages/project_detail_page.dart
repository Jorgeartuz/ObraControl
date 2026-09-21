import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/module_card.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/section_header.dart';
import 'daily_records_list_page.dart';
import 'package:obrafcontrol_test/features/material_entries/presentation/pages/material_entries_list_page.dart';
import 'package:obrafcontrol_test/features/material_exits/presentation/pages/material_exits_list_page.dart';
import 'machinery_list_page.dart';

class ProjectDetailPage extends StatelessWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project.name),
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailyRecordsListPage(project: project))),
                      ),
                      ModuleCard(
                        title: "Entradas",
                        subtitle: "Ingreso de material",
                        icon: Icons.input_rounded,
                        variant: ModuleCardVariant.success,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialEntriesListPage(project: project))),
                      ),
                      ModuleCard(
                        title: "Salidas",
                        subtitle: "Retiro de material",
                        icon: Icons.output_rounded,
                        variant: ModuleCardVariant.error,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialExitsListPage(project: project))),
                      ),
                      ModuleCard(
                        title: "Maquinaria",
                        subtitle: "Control de equipo",
                        icon: Icons.engineering_outlined,
                        variant: ModuleCardVariant.warning,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MachineryListPage(project: project))),
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
              const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(project.location ?? "Ubicación no especificada", style: const TextStyle(color: AppColors.textPrimary))),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(project.description ?? "Sin descripción", style: const TextStyle(color: AppColors.textPrimary))),
            ],
          ),
        ],
      ),
    );
  }
}