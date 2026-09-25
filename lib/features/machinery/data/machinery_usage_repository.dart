import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Registro de uso/horómetro de maquinaria.
///
/// Entidad sincronizable: sigue el patrón local transaction -> SyncQueue ->
/// SyncEngine -> Supabase (tabla remota `machinery_usage_logs`). Esa tabla
/// remota debe crearse manualmente en Supabase antes de que la sincronización
/// tenga éxito (ver documentación); mientras tanto, los intentos de sync
/// fallarán de forma controlada (quedan en SyncQueue con estado `failed`) sin
/// afectar el resto de entidades ni perder datos locales.
class MachineryUsageRepository {
  MachineryUsageRepository(this._db, this._syncAfterMutation);

  final AppDatabase _db;
  final Future<void> Function() _syncAfterMutation;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<MachineryUsageLog>> watchUsageLogs(String machineId) =>
      (_db.select(_db.machineryUsageLogs)
            ..where((table) => table.machineId.equals(machineId))
            ..orderBy([(table) => OrderingTerm.desc(table.date)]))
          .watch();

  Stream<List<MachineryUsageLog>> watchUsageLogsByProject(String projectId) =>
      (_db.select(_db.machineryUsageLogs)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.desc(table.date)]))
          .watch();

  Future<void> addUsageLog({
    required String machineId,
    required String projectId,
    required DateTime date,
    required double horometerStart,
    required double horometerEnd,
    String? observations,
  }) async {
    if (horometerStart < 0 || horometerEnd < 0) {
      throw ArgumentError('El horómetro no puede ser negativo.');
    }
    if (horometerEnd < horometerStart) {
      throw ArgumentError('El horómetro final no puede ser menor que el inicial.');
    }

    final user = _requireUser();
    final hoursWorked = double.parse((horometerEnd - horometerStart).toStringAsFixed(2));
    final log = MachineryUsageLog(
      id: const Uuid().v4(),
      machineId: machineId,
      projectId: projectId,
      date: date,
      horometerStart: horometerStart,
      horometerEnd: horometerEnd,
      hoursWorked: hoursWorked,
      observations: observations,
      createdAt: DateTime.now(),
      createdBy: user.id,
      syncStatus: SyncStatus.pending,
    );

    await _db.transaction(() async {
      await _db.into(_db.machineryUsageLogs).insert(log);
      await _queue('create', log.id, log);
    });
    await _syncAfterMutation();
  }

  Future<void> deleteUsageLog(String id) async {
    _requireUser();
    await _db.transaction(() async {
      await (_db.delete(
        _db.machineryUsageLogs,
      )..where((table) => table.id.equals(id))).go();
      await _queue('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> _queue(String action, String id, MachineryUsageLog? log) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion.insert(
          entityType: 'machinery_usage_log',
          entityId: id,
          action: action,
          payload: jsonEncode(log == null ? {'id': id} : _payload(log)),
          syncStatus: SyncStatus.pending,
        ),
      );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }

  Map<String, dynamic> _payload(MachineryUsageLog log) => {
    'id': log.id,
    'machine_id': log.machineId,
    'project_id': log.projectId,
    'date': log.date.toIso8601String(),
    'horometer_start': log.horometerStart,
    'horometer_end': log.horometerEnd,
    'hours_worked': log.hoursWorked,
    'observations': log.observations,
    'created_at': log.createdAt.toIso8601String(),
    'created_by': log.createdBy,
  };
}

final Provider<MachineryUsageRepository> machineryUsageRepositoryProvider =
    Provider<MachineryUsageRepository>(
      (ref) => MachineryUsageRepository(
        ref.watch(databaseProvider),
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      ),
    );

final machineryUsageLogsProvider =
    StreamProvider.family<List<MachineryUsageLog>, String>(
      (ref, machineId) =>
          ref.watch(machineryUsageRepositoryProvider).watchUsageLogs(machineId),
    );

final machineryUsageLogsByProjectProvider =
    StreamProvider.family<List<MachineryUsageLog>, String>(
      (ref, projectId) => ref
          .watch(machineryUsageRepositoryProvider)
          .watchUsageLogsByProject(projectId),
    );
