import 'package:flutter/material.dart';
import '../../../../core/database/local_database.dart';

class MaterialEntriesListPage extends StatelessWidget {
  final Project project;
  const MaterialEntriesListPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrada de material")),
      body: const Center(child: Text("Lista de entradas")),
    );
  }
}