import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/features/auth/presentation/widgets/auth_gate.dart';

class ObraControlApp extends StatelessWidget {
  const ObraControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObraControl',
      debugShowCheckedModeBanner: false,

      // Aplicamos el Design System centralizado
      theme: AppTheme.lightTheme.copyWith(
  textTheme: Typography.englishLike2018.apply(bodyColor: AppColors.textPrimary),
),
      // Página inicial definida en el Step 2
      home: const AuthGate(),
    );
  }
}
