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
    switch (variant) {
      case ModuleCardVariant.primary:
        return AppColors.primary;
      case ModuleCardVariant.info:
        return AppColors.info;
      case ModuleCardVariant.success:
        return AppColors.success;
      case ModuleCardVariant.warning:
        return AppColors.warning;
      case ModuleCardVariant.error:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(variant);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
