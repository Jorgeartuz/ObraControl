import 'package:flutter/material.dart';

class CreateMaterialExitPage extends StatelessWidget {
  final String projectId;
  const CreateMaterialExitPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Registrar salida")));
  }
}