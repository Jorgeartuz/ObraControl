import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  
  const SectionHeader({
    super.key, 
    required this.title
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}