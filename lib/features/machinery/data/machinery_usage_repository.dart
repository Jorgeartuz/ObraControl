import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Registro de uso/horómetro de maquinaria.
///
/// NOTA ARQUITECTÓNICA: esta entidad es deliberadamente LOCAL por ahora.
/// La tabla remota `machinery_usage_logs` todavía no existe en Supabase, así
/// que no se encola en SyncQueue (evita fallos sistemáticos de sincronización
/// contra una tabla inexistente). Cuando el backend agregue esa tabla, este
/// repositorio deberá encolar create/delete igual que el resto de entidades.
class MachineryUsageRepository {
  MachineryUsageRepository(this._db);

  final AppDatabase _db;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<MachineryUsageLog>> watchUsageLogs(String machineId) =>
      (_db.select(_db.machineryUsageLogs)
            ..where((table) => table.machineId.equals(machineId))
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

    await _db.into(_db.machineryUsageLogs).insert(log);
  }

  Future<void> deleteUsageLog(String id) async {
    _requireUser();
    await (_db.delete(
      _db.machineryUsageLogs,
    )..where((table) => table.id.equals(id))).go();
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }
}

final Provider<MachineryUsageRepository> machineryUsageRepositoryProvider =
    Provider<MachineryUsageRepository>(
      (ref) => MachineryUsageRepository(ref.watch(databaseProvider)),
    );

final machineryUsageLogsProvider =
    StreamProvider.family<List<MachineryUsageLog>, String>(
      (ref, machineId) =>
          ref.watch(machineryUsageRepositoryProvider).watchUsageLogs(machineId),
    );
