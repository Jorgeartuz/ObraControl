import 'package:flutter/material.dart';
import '../features/projects/presentation/pages/projects_list_page.dart';

class ObraControlApp extends StatelessWidget {
  const ObraControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObraControl',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const ProjectsListPage(),
    );
  }
}