import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/features/daily_records/data/daily_record_repository.dart';
import 'package:obrafcontrol_test/features/dump_trucks/data/dump_truck_repository.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_repository.dart';
import 'package:obrafcontrol_test/features/machinery/data/machinery_usage_repository.dart';
import 'package:obrafcontrol_test/features/material_entries/data/material_entry_repository.dart';
import 'package:obrafcontrol_test/features/material_exits/data/material_exit_repository.dart';

/// Indicadores del dashboard: cada uno es un provider derivado que reutiliza
/// el stream de lista ya existente del módulo correspondiente y expone su
/// conteo real (`.length`), sin queries nuevas ni datos mock. Se recalculan
/// automáticamente cuando el stream de origen emite (alta/baja/edición).

final dailyRecordsCountProvider = Provider.family<AsyncValue<int>, String>(
  (ref, projectId) => ref
      .watch(dailyRecordsProvider(projectId))
      .whenData((records) => records.length),
);

final materialEntriesCountProvider = Provider.family<AsyncValue<int>, String>(
  (ref, projectId) => ref
      .watch(materialEntriesStreamProvider(projectId))
      .whenData((entries) => entries.length),
);

final materialExitsCountProvider = Provider.family<AsyncValue<int>, String>(
  (ref, projectId) => ref
      .watch(materialExitStreamProvider(projectId))
      .whenData((exits) => exits.length),
);

final machineryCountProvider = Provider.family<AsyncValue<int>, String>(
  (ref, projectId) => ref
      .watch(machineryStreamProvider(projectId))
      .whenData((machines) => machines.length),
);

final machineryUsageCountProvider = Provider.family<AsyncValue<int>, String>(
  (ref, projectId) => ref
      .watch(machineryUsageLogsByProjectProvider(projectId))
      .whenData((logs) => logs.length),
);

final dumpTrucksCountProvider = Provider.family<AsyncValue<int>, String>(
  (ref, projectId) => ref
      .watch(dumpTruckLogsProvider(projectId))
      .whenData((logs) => logs.length),
);
