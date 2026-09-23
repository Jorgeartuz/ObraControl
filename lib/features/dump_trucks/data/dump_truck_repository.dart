import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Control de entrada/salida de volquetas.
///
/// Entidad sincronizable: sigue el patrón local transaction -> SyncQueue ->
/// SyncEngine -> Supabase (tabla remota `dump_truck_logs`). Esa tabla remota
/// debe crearse manualmente en Supabase antes de que la sincronización tenga
/// éxito (ver documentación); mientras tanto, los intentos de sync fallarán
/// de forma controlada (quedan en SyncQueue con estado `failed`) sin afectar
/// al resto de entidades ni perder datos locales.
class DumpTruckRepository {
  DumpTruckRepository(this._db, this._syncAfterMutation);

  final AppDatabase _db;
  final Future<void> Function() _syncAfterMutation;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<DumpTruckLog>> watchByProject(String projectId) =>
      (_db.select(_db.dumpTruckLogs)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.desc(table.entryTime)]))
          .watch();

  Future<void> registerEntry(DumpTruckLog log) async {
    if (log.quantity <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que 0.');
    }
    final user = _requireUser();
    final toSave = log.createdBy == null
        ? log.copyWith(createdBy: Value(user.id))
        : log;
    await _db.transaction(() async {
      await _db.into(_db.dumpTruckLogs).insert(toSave);
      await _queue('create', toSave.id, toSave);
    });
    await _syncAfterMutation();
  }

  /// Registra la hora de salida de un registro cuya salida está pendiente.
  Future<void> registerExit(String id, DateTime exitTime) async {
    _requireUser();
    final existing = await (_db.select(
      _db.dumpTruckLogs,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw StateError('El registro ya no existe.');
    }
    if (exitTime.isBefore(existing.entryTime)) {
      throw ArgumentError('La hora de salida no puede ser anterior a la entrada.');
    }
    await _persistUpdate(existing.copyWith(exitTime: Value(exitTime)));
  }

  Future<void> updateLog(DumpTruckLog log) async {
    if (log.quantity <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que 0.');
    }
    _requireUser();
    final existing = await (_db.select(
      _db.dumpTruckLogs,
    )..where((table) => table.id.equals(log.id))).getSingleOrNull();
    if (existing?.exitTime != null && log.entryTime.isAfter(existing!.exitTime!)) {
      throw ArgumentError('La hora de entrada no puede ser posterior a la hora de salida ya registrada.');
    }
    final toSave = existing == null
        ? log
        : log.copyWith(
            createdAt: existing.createdAt,
            createdBy: Value(existing.createdBy),
            exitTime: Value(existing.exitTime),
          );
    await _persistUpdate(toSave);
  }

  Future<void> deleteLog(String id) async {
    _requireUser();
    await _db.transaction(() async {
      await (_db.delete(
        _db.dumpTruckLogs,
      )..where((table) => table.id.equals(id))).go();
      await _queue('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> _persistUpdate(DumpTruckLog log) async {
    await _db.transaction(() async {
      await _db.update(_db.dumpTruckLogs).replace(log);
      await _queue('update', log.id, log);
    });
    await _syncAfterMutation();
  }

  Future<void> _queue(String action, String id, DumpTruckLog? log) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion.insert(
          entityType: 'dump_truck_log',
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

  Map<String, dynamic> _payload(DumpTruckLog log) => {
    'id': log.id,
    'project_id': log.projectId,
    'plate': log.plate,
    'driver': log.driver,
    'material': log.material,
    'quantity': log.quantity,
    'unit': log.unit,
    'date': log.date.toIso8601String(),
    'entry_time': log.entryTime.toIso8601String(),
    'exit_time': log.exitTime?.toIso8601String(),
    'observations': log.observations,
    'created_at': log.createdAt.toIso8601String(),
    'created_by': log.createdBy,
  };
}

final Provider<DumpTruckRepository> dumpTruckRepositoryProvider =
    Provider<DumpTruckRepository>(
      (ref) => DumpTruckRepository(
        ref.watch(databaseProvider),
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      ),
    );

final dumpTruckLogsProvider = StreamProvider.family<List<DumpTruckLog>, String>(
  (ref, projectId) =>
      ref.watch(dumpTruckRepositoryProvider).watchByProject(projectId),
);
