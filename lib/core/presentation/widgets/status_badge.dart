import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final SyncStatus status;
  
  const StatusBadge({
    super.key, 
    required this.status
  });

  @override
  Widget build(BuildContext context) {
    // Definimos los colores según el estado
    final Color color = _getColorForStatus(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getColorForStatus(SyncStatus status) {
    // Al usar switch sobre un enum, Dart sabe que ya cubrimos todos los casos
    return switch (status) {
      SyncStatus.synced => AppColors.synced,
      SyncStatus.pending => AppColors.pending,
      SyncStatus.syncing => Colors.blue,
      SyncStatus.failed => Colors.red,
    };
  }
}