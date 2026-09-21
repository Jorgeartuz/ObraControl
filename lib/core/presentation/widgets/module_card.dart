import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';

enum ModuleCardVariant { primary, info, success, warning, error }

class ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ModuleCardVariant variant;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.variant,
    required this.onTap,
  });

  Color _getColor(ModuleCardVariant variant) {
    return switch (variant) {
      ModuleCardVariant.primary => AppColors.primary,
      ModuleCardVariant.info => AppColors.info,
      ModuleCardVariant.success => AppColors.success,
      ModuleCardVariant.warning => AppColors.warning,
      ModuleCardVariant.error => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(variant);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: AppColors.textPrimary
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}