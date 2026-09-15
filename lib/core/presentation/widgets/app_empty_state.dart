import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
