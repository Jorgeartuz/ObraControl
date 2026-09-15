import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/features/projects/presentation/pages/projects_list_page.dart';

class ObraControlApp extends StatelessWidget {
  const ObraControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObraControl',
      debugShowCheckedModeBanner: false,

      // Aplicamos el Design System centralizado
      theme: AppTheme.lightTheme,

      // Página inicial definida en el Step 2
      home: const ProjectsListPage(),
    );
  }
}
