import 'package:flutter/material.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/features/dashboard/domain/activity_item.dart';

/// Metadatos de presentación (etiqueta/ícono/color) por [ActivityType].
/// Fuente única compartida entre `DashboardActivityList` (cada `_ActivityTile`)
/// y `DashboardFilterBar` (los chips de tipo), para no duplicar el mapeo.
class ActivityTypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  const ActivityTypeMeta(this.label, this.icon, this.color);
}

ActivityTypeMeta activityTypeMeta(ActivityType type) {
  return switch (type) {
    ActivityType.dailyRecord => const ActivityTypeMeta(
      'Registro diario',
      Icons.camera_alt_outlined,
      AppColors.primary,
    ),
    ActivityType.materialEntry => const ActivityTypeMeta(
      'Entrada de material',
      Icons.input_rounded,
      AppColors.success,
    ),
    ActivityType.materialExit => const ActivityTypeMeta(
      'Salida de material',
      Icons.output_rounded,
      AppColors.error,
    ),
    ActivityType.machineryUsage => const ActivityTypeMeta(
      'Uso de maquinaria',
      Icons.timelapse_outlined,
      AppColors.warning,
    ),
    ActivityType.dumpTruck => const ActivityTypeMeta(
      'Volqueta',
      Icons.local_shipping_outlined,
      AppColors.info,
    ),
  };
}
