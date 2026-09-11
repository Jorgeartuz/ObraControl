import 'package:flutter/material.dart';
import '../../../../core/database/local_database.dart';
import 'daily_records_list_page.dart';
import 'material_entries_list_page.dart';
import 'package:obrafcontrol_test/features/material_exits/presentation/pages/material_exits_list_page.dart';
import 'machinery_list_page.dart';

class ProjectDetailPage extends StatelessWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProjectHeader(project: project),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                _ModuleCard(
                  title: "Registro fotográfico diario",
                  icon: Icons.camera_alt_outlined,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DailyRecordsListPage(project: project))),
                ),
                _ModuleCard(
                  title: "Entrada de material",
                  icon: Icons.login_rounded,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MaterialEntriesListPage(project: project))),
                ),
                _ModuleCard(
                  title: "Salida de material",
                  icon: Icons.logout_rounded,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MaterialExitsListPage(project: project))),
                ),
                _ModuleCard(
                  title: "Maquinaria en obra",
                  icon: Icons.engineering_outlined,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MachineryListPage(project: project))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final Project project;
  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(project.location ?? "Sin ubicación", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.description ?? "Sin descripción", style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}