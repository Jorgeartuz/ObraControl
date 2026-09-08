import 'package:flutter/material.dart';
import '../../../../core/database/local_database.dart';

class MaterialExitsListPage extends StatelessWidget {
  final Project project;
  const MaterialExitsListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salida de material")),
      body: const Center(child: Text("Lista de salidas")),
    );
  }
}