import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';

class MaterialEntryRepository {
  final AppDatabase _db;
  MaterialEntryRepository(this._db);

  Stream<List<MaterialEntry>> watchEntriesByProject(String projectId) {
    return (_db.select(_db.materialEntries)
      ..where((t) => t.projectId.equals(projectId))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
      .watch();
  }

  Future<void> addEntry(MaterialEntry entry) async {
    await _db.transaction(() async {
      await _db.into(_db.materialEntries).insert(entry);
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
        entityType: 'material_entry',
        entityId: entry.id,
        action: 'create',
        payload: jsonEncode(entry.toJson()), // Drift genera toJson automáticamente
        syncStatus: SyncStatus.pending,
      ));
    });
  }
}

final materialEntryRepositoryProvider = Provider((ref) => MaterialEntryRepository(ref.watch(databaseProvider)));