import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/features/dashboard/presentation/providers/dashboard_indicators_provider.dart';

/// Grid compacto de indicadores reales de la obra (Bloque 1: providers de
/// conteo). Puramente de presentación: no ejecuta queries propias, solo lee
/// los `Provider.family<AsyncValue<int>, String>` ya existentes.
class DashboardIndicatorsGrid extends ConsumerWidget {
  final String projectId;
  const DashboardIndicatorsGrid({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = [
      _IndicatorData(
        label: 'Registros diarios',
        icon: Icons.camera_alt_outlined,
        color: AppColors.primary,
        count: ref.watch(dailyRecordsCountProvider(projectId)),
      ),
      _IndicatorData(
        label: 'Entradas de material',
        icon: Icons.input_rounded,
        color: AppColors.success,
        count: ref.watch(materialEntriesCountProvider(projectId)),
      ),
      _IndicatorData(
        label: 'Salidas de material',
        icon: Icons.output_rounded,
        color: AppColors.error,
        count: ref.watch(materialExitsCountProvider(projectId)),
      ),
      _IndicatorData(
        label: 'Maquinaria',
        icon: Icons.engineering_outlined,
        color: AppColors.warning,
        count: ref.watch(machineryCountProvider(projectId)),
      ),
      _IndicatorData(
        label: 'Uso de maquinaria',
        icon: Icons.timelapse_outlined,
        color: AppColors.warning,
        count: ref.watch(machineryUsageCountProvider(projectId)),
      ),
      _IndicatorData(
        label: 'Volquetas',
        icon: Icons.local_shipping_outlined,
        color: AppColors.info,
        count: ref.watch(dumpTrucksCountProvider(projectId)),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        for (final indicator in indicators) _IndicatorTile(data: indicator),
      ],
    );
  }
}

class _IndicatorData {
  final String label;
  final IconData icon;
  final Color color;
  final AsyncValue<int> count;

  const _IndicatorData({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });
}

/// Tarjeta individual de un indicador. Un bloque futuro puede habilitar
/// navegación agregando un `VoidCallback? onTap` aquí y pasándolo al
/// `InkWell` de abajo, sin más cambios estructurales.
class _IndicatorTile extends StatelessWidget {
  final _IndicatorData data;

  const _IndicatorTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const SizedBox(height: 8),
              _CountValue(count: data.count, color: data.color),
              const SizedBox(height: 2),
              Text(
                data.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountValue extends StatelessWidget {
  final AsyncValue<int> count;
  final Color color;

  const _CountValue({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return count.when(
      data: (value) => Text(
        '$value',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
      ),
      loading: () => const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => const Icon(Icons.error_outline, size: 18, color: AppColors.error),
    );
  }
}
