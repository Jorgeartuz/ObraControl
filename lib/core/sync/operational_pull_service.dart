import 'package:drift/drift.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperationalPullService {
  OperationalPullService(this._db);

  final AppDatabase _db;
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> pullAll() async {
    await _pullDailyRecords();
    await _pullMaterialEntries();
    await _pullMaterialExits();
    await _pullMachinery();
    await _pullMachineryUsageLogs();
    await _pullDumpTruckLogs();
  }

  Future<bool> _hasLocalChange(String type, String id) async =>
      (await (_db.select(_db.syncQueue)..where(
            (table) =>
                table.entityType.equals(type) &
                table.entityId.equals(id) &
                table.syncStatus.equals(SyncStatus.synced.index).not(),
          ))
          .get())
          .isNotEmpty;

  Future<void> _pullDailyRecords() async {
    final rows = await _client.from('daily_records').select() as List<dynamic>;
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLocalChange('daily_record', id)) continue;
      final remote = DailyRecord(
        id: id, projectId: row['project_id'], date: DateTime.parse(row['date']),
        description: row['description'], observations: row['observations'],
        createdAt: DateTime.parse(row['created_at']),
        updatedAt: DateTime.parse(row['updated_at']), createdBy: row['created_by'],
        syncStatus: SyncStatus.synced,
      );
      final local = await (_db.select(_db.dailyRecords)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        await _db.into(_db.dailyRecords).insertOnConflictUpdate(remote);
      }
    }
  }

  Future<void> _pullMaterialEntries() async {
    final rows = await _client.from('material_entries').select() as List<dynamic>;
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLocalChange('material_entry', id)) continue;
      final remote = MaterialEntry(
        id: id, projectId: row['project_id'], date: DateTime.parse(row['date']),
        materialName: row['material_name'], quantity: (row['quantity'] as num).toDouble(),
        unit: row['unit'], supplier: row['supplier'], observations: row['observations'],
        createdAt: DateTime.parse(row['created_at']), createdBy: row['created_by'],
        syncStatus: SyncStatus.synced,
      );
      await _db.into(_db.materialEntries).insertOnConflictUpdate(remote);
    }
  }

  Future<void> _pullMaterialExits() async {
    final rows = await _client.from('material_exits').select() as List<dynamic>;
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLocalChange('material_exit', id)) continue;
      final remote = MaterialExit(
        id: id, projectId: row['project_id'], date: DateTime.parse(row['date']),
        materialName: row['material_name'], quantity: (row['quantity'] as num).toDouble(),
        unit: row['unit'], destination: row['destination'], responsible: row['responsible'],
        observations: row['observations'], createdAt: DateTime.parse(row['created_at']),
        createdBy: row['created_by'], syncStatus: SyncStatus.synced,
      );
      await _db.into(_db.materialExits).insertOnConflictUpdate(remote);
    }
  }

  Future<void> _pullMachinery() async {
    final rows = await _client.from('machinery').select() as List<dynamic>;
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLocalChange('machinery', id)) continue;
      await _db.into(_db.machinery).insertOnConflictUpdate(Machine(
        id: id, projectId: row['project_id'], name: row['name'], type: row['type'],
        description: row['description'], createdAt: DateTime.parse(row['created_at']),
        createdBy: row['created_by'], syncStatus: SyncStatus.synced,
      ));
    }
  }

  /// `machinery_usage_logs` no tiene `updated_at` remoto (es un registro
  /// histórico inmutable, no se edita tras crearse), así que se sigue el
  /// mismo patrón que `machinery`/`material_entries`/`material_exits`:
  /// se omite si hay un cambio local pendiente/fallido y, si no, se aplica
  /// `insertOnConflictUpdate` directamente.
  Future<void> _pullMachineryUsageLogs() async {
    final rows = await _client.from('machinery_usage_logs').select() as List<dynamic>;
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLocalChange('machinery_usage_log', id)) continue;
      await _db.into(_db.machineryUsageLogs).insertOnConflictUpdate(MachineryUsageLog(
        id: id,
        machineId: row['machine_id'],
        projectId: row['project_id'],
        date: DateTime.parse(row['date']),
        horometerStart: (row['horometer_start'] as num).toDouble(),
        horometerEnd: (row['horometer_end'] as num).toDouble(),
        hoursWorked: (row['hours_worked'] as num).toDouble(),
        observations: row['observations'],
        createdAt: DateTime.parse(row['created_at']),
        createdBy: row['created_by'],
        syncStatus: SyncStatus.synced,
      ));
    }
  }

  /// `dump_truck_logs` tampoco tiene `updated_at` remoto, aunque sí se edita
  /// (p. ej. al registrar la salida). Se mantiene la misma estrategia que el
  /// resto de entidades sin `updated_at`: `_hasLocalChange` evita pisar una
  /// edición local pendiente/fallida (incluida una salida recién registrada
  /// offline), y en caso contrario se aplica `insertOnConflictUpdate`.
  Future<void> _pullDumpTruckLogs() async {
    final rows = await _client.from('dump_truck_logs').select() as List<dynamic>;
    for (final row in rows) {
      final id = row['id'] as String;
      if (await _hasLocalChange('dump_truck_log', id)) continue;
      final exitTime = row['exit_time'];
      await _db.into(_db.dumpTruckLogs).insertOnConflictUpdate(DumpTruckLog(
        id: id,
        projectId: row['project_id'],
        plate: row['plate'],
        driver: row['driver'],
        material: row['material'],
        quantity: (row['quantity'] as num).toDouble(),
        unit: row['unit'],
        date: DateTime.parse(row['date']),
        entryTime: DateTime.parse(row['entry_time']),
        exitTime: exitTime == null ? null : DateTime.parse(exitTime as String),
        observations: row['observations'],
        createdAt: DateTime.parse(row['created_at']),
        createdBy: row['created_by'],
        syncStatus: SyncStatus.synced,
      ));
    }
  }
}
