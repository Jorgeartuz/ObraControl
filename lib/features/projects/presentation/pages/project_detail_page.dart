import 'package:flutter/material.dart';

class ProjectDetailPage extends StatelessWidget {
  final dynamic project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          const Text("Módulos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          _buildModuleTile("Actividades", Icons.list_alt),
          _buildModuleTile("Evidencias (Fotos)", Icons.camera_alt),
          _buildModuleTile("Maquinaria", Icons.engineering),
          _buildModuleTile("Volquetas", Icons.local_shipping),
          _buildModuleTile("Sincronización", Icons.sync),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Descripción: ${project.description ?? 'Sin descripción'}", style: const TextStyle(color: Colors.grey)),
            const Divider(),
            Text("Estado: ${project.status}"),
            Text("Ubicación: ${project.location ?? 'No definida'}"),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        trailing: const Text("Próximamente", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }
}