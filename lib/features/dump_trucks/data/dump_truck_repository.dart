import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Control de entrada/salida de volquetas.
///
/// NOTA ARQUITECTÓNICA: esta entidad es deliberadamente LOCAL por ahora.
/// La tabla remota `dump_truck_logs` todavía no existe en Supabase, así que
/// no se encola en SyncQueue (evita fallos sistemáticos de sincronización
/// contra una tabla inexistente). Cuando el backend agregue esa tabla, este
/// repositorio deberá encolar create/update/delete igual que el resto de
/// entidades (ver métodos comentados de referencia en el reporte final).
class DumpTruckRepository {
  DumpTruckRepository(this._db);

  final AppDatabase _db;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<DumpTruckLog>> watchByProject(String projectId) =>
      (_db.select(_db.dumpTruckLogs)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.desc(table.entryTime)]))
          .watch();

  Future<void> registerEntry(DumpTruckLog log) async {
    final user = _requireUser();
    final toSave = log.createdBy == null
        ? log.copyWith(createdBy: Value(user.id))
        : log;
    await _db.into(_db.dumpTruckLogs).insert(toSave);
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
    await _db.update(_db.dumpTruckLogs).replace(existing.copyWith(exitTime: Value(exitTime)));
  }

  Future<void> updateLog(DumpTruckLog log) async {
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
    await _db.update(_db.dumpTruckLogs).replace(toSave);
  }

  Future<void> deleteLog(String id) async {
    _requireUser();
    await (_db.delete(
      _db.dumpTruckLogs,
    )..where((table) => table.id.equals(id))).go();
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }
}

final Provider<DumpTruckRepository> dumpTruckRepositoryProvider =
    Provider<DumpTruckRepository>(
      (ref) => DumpTruckRepository(ref.watch(databaseProvider)),
    );

final dumpTruckLogsProvider = StreamProvider.family<List<DumpTruckLog>, String>(
  (ref, projectId) =>
      ref.watch(dumpTruckRepositoryProvider).watchByProject(projectId),
);
