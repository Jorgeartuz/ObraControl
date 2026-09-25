import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';

/// Tipos de evento operativo que puede representar una [ActivityItem] en el
/// feed de actividad reciente del dashboard. Uno por módulo existente cuyos
/// registros tienen una fecha de actividad propia (no metadatos de fila).
enum ActivityType {
  dailyRecord,
  materialEntry,
  materialExit,
  machineryUsage,
  dumpTruck,
}

/// Representación normalizada de un evento de cualquier módulo, usada
/// únicamente para armar el feed de actividad reciente del dashboard.
/// No es una entidad de base de datos: se construye en memoria combinando
/// los streams ya existentes de cada repositorio.
class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.syncStatus,
    required this.referenceId,
  });

  /// Módulo de origen del evento.
  final ActivityType type;

  /// Texto principal a mostrar (p. ej. descripción del registro diario,
  /// nombre del material, placa de la volqueta).
  final String title;

  /// Texto secundario a mostrar (p. ej. cantidad/unidad, máquina asociada).
  final String subtitle;

  /// Fecha de actividad ya normalizada (no `createdAt`), usada para ordenar
  /// el feed. Cada fuente la deriva de su propio campo de fecha de negocio.
  final DateTime timestamp;

  /// Estado de sincronización del registro subyacente.
  final SyncStatus syncStatus;

  /// Id del registro original en su tabla de origen. Se conserva para poder
  /// navegar al detalle/módulo correspondiente en un bloque futuro.
  final String referenceId;
}
