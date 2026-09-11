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
    final Color color = _getColorForStatus(status);
    final String label = _getLabelForStatus(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForStatus(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced => AppColors.synced,
      SyncStatus.pending => AppColors.pending,
      SyncStatus.syncing => Colors.blue,
      SyncStatus.failed => Colors.red,
    };
  }

  String _getLabelForStatus(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced => "Sincronizado",
      SyncStatus.pending => "Pendiente",
      SyncStatus.syncing => "Sincronizando",
      SyncStatus.failed => "Error",
    };
  }
}