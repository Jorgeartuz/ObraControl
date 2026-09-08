import 'package:flutter/material.dart';
import '../../../../core/database/local_database.dart';

class DailyRecordsListPage extends StatelessWidget {
  final Project project;
  const DailyRecordsListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro fotográfico")),
      body: const Center(child: Text("Próximamente: Cámara y Fotos")),
    );
  }
}