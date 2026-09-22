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
}
