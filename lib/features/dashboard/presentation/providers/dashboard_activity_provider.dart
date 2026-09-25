import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/features/dashboard/domain/activity_item.dart';
import 'package:obrafcontrol_test/features/daily_records/data/daily_record_repository.dart';
import 'package:obrafcontrol_test/features/dump_trucks/data/dump_truck_repository.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_usage_repository.dart';
import 'package:obrafcontrol_test/features/material_entries/data/material_entry_repository.dart';
import 'package:obrafcontrol_test/features/material_exits/data/material_exit_repository.dart';

/// Máximo de elementos que expone el feed de actividad reciente.
const int dashboardActivityLimit = 20;

/// Feed de actividad reciente del dashboard: combina, en memoria, los
/// streams de lista ya existentes de cada módulo (sin queries nuevas), los
/// normaliza a [ActivityItem], ordena por fecha descendente y devuelve como
/// máximo [dashboardActivityLimit] elementos.
///
/// Un registro diario con fotografías se representa como UNA sola actividad
/// (la fotografía no tiene su propia fecha de negocio, es un adjunto del
/// registro), no una actividad por cada fotografía.
///
/// Es un `Provider` (no `StreamProvider`): Riverpod lo recalcula solo cuando
/// alguno de los `StreamProvider`s observados emite un nuevo valor, sin
/// necesitar combinadores de streams externos (sin dependencias nuevas).
final dashboardActivityProvider = Provider.family<AsyncValue<List<ActivityItem>>, String>(
  (ref, projectId) {
    final dailyRecordsAsync = ref.watch(dailyRecordsProvider(projectId));
    final materialEntriesAsync = ref.watch(materialEntriesStreamProvider(projectId));
    final materialExitsAsync = ref.watch(materialExitStreamProvider(projectId));
    final machineryUsageAsync = ref.watch(machineryUsageLogsByProjectProvider(projectId));
    final dumpTrucksAsync = ref.watch(dumpTruckLogsProvider(projectId));

    // Se comprueba cada fuente por separado (en vez de agruparlas en una
    // lista) porque cada AsyncValue tiene un tipo genérico distinto
    // (AsyncValue<List<DailyRecord>>, AsyncValue<List<MaterialEntry>>, ...);
    // agruparlas forzaría a Dart a unificar un tipo común incompatible.
    if (dailyRecordsAsync.hasError) {
      return AsyncValue.error(dailyRecordsAsync.error!, dailyRecordsAsync.stackTrace!);
    }
    if (materialEntriesAsync.hasError) {
      return AsyncValue.error(materialEntriesAsync.error!, materialEntriesAsync.stackTrace!);
    }
    if (materialExitsAsync.hasError) {
      return AsyncValue.error(materialExitsAsync.error!, materialExitsAsync.stackTrace!);
    }
    if (machineryUsageAsync.hasError) {
      return AsyncValue.error(machineryUsageAsync.error!, machineryUsageAsync.stackTrace!);
    }
    if (dumpTrucksAsync.hasError) {
      return AsyncValue.error(dumpTrucksAsync.error!, dumpTrucksAsync.stackTrace!);
    }

    final stillLoading = (dailyRecordsAsync.isLoading && !dailyRecordsAsync.hasValue) ||
        (materialEntriesAsync.isLoading && !materialEntriesAsync.hasValue) ||
        (materialExitsAsync.isLoading && !materialExitsAsync.hasValue) ||
        (machineryUsageAsync.isLoading && !machineryUsageAsync.hasValue) ||
        (dumpTrucksAsync.isLoading && !dumpTrucksAsync.hasValue);
    if (stillLoading) {
      return const AsyncValue.loading();
    }

    final items = <ActivityItem>[
      for (final record in dailyRecordsAsync.value ?? const [])
        ActivityItem(
          type: ActivityType.dailyRecord,
          title: record.description,
          subtitle: (record.observations?.isNotEmpty ?? false)
              ? record.observations!
              : 'Registro diario',
          timestamp: record.date,
          syncStatus: record.syncStatus,
          referenceId: record.id,
        ),
      for (final entry in materialEntriesAsync.value ?? const [])
        ActivityItem(
          type: ActivityType.materialEntry,
          title: entry.materialName,
          subtitle: '${entry.quantity} ${entry.unit} · Entrada',
          timestamp: entry.date,
          syncStatus: entry.syncStatus,
          referenceId: entry.id,
        ),
      for (final exit in materialExitsAsync.value ?? const [])
        ActivityItem(
          type: ActivityType.materialExit,
          title: exit.materialName,
          subtitle: '${exit.quantity} ${exit.unit} · Salida a ${exit.destination}',
          timestamp: exit.date,
          syncStatus: exit.syncStatus,
          referenceId: exit.id,
        ),
      for (final usage in machineryUsageAsync.value ?? const [])
        ActivityItem(
          type: ActivityType.machineryUsage,
          title: 'Uso de maquinaria',
          subtitle: '${usage.hoursWorked.toStringAsFixed(2)} h trabajadas',
          timestamp: usage.date,
          syncStatus: usage.syncStatus,
          referenceId: usage.id,
        ),
      for (final log in dumpTrucksAsync.value ?? const [])
        ActivityItem(
          type: ActivityType.dumpTruck,
          title: log.plate,
          subtitle: '${log.material} · ${log.quantity} ${log.unit}',
          timestamp: log.entryTime,
          syncStatus: log.syncStatus,
          referenceId: log.id,
        ),
    ];

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final limited = items.length > dashboardActivityLimit
        ? items.sublist(0, dashboardActivityLimit)
        : items;

    return AsyncValue.data(limited);
  },
);
