import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/core/presentation/widgets/status_badge.dart';
import 'package:obrafcontrol_test/features/dashboard/domain/activity_item.dart';
import 'package:obrafcontrol_test/features/dashboard/presentation/providers/dashboard_activity_provider.dart';
import 'activity_type_meta.dart';

/// Feed de actividad reciente de la obra (`dashboardActivityProvider`).
/// Puramente de presentación: el provider ya entrega la lista combinada,
/// ordenada y limitada a 20 elementos. Es un feed informativo de solo
/// lectura, sin búsqueda ni filtros.
class DashboardActivityList extends ConsumerWidget {
  final String projectId;
  const DashboardActivityList({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dashboardActivityProvider(projectId));

    return activityAsync.when(
      data: (items) {
        if (items.isEmpty) return const _EmptyActivityState();
        return Column(
          children: [
            for (final item in items) _ActivityTile(item: item),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No se pudo cargar la actividad reciente: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.history_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            'Sin actividad reciente',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Los registros de los módulos de esta obra aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = activityTypeMeta(item.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: meta.color.withValues(alpha: 0.1),
          child: Icon(meta.icon, color: meta.color, size: 18),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        subtitle: Text(
          '${meta.label} · ${item.subtitle}\n${DateFormat('dd/MM/yyyy - HH:mm').format(item.timestamp)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        isThreeLine: true,
        trailing: StatusBadge(status: item.syncStatus),
      ),
    );
  }
}
