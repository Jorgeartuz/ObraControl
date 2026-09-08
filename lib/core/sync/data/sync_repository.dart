import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../database/local_database.dart';
import '../domain/sync_status.dart';
import '../../../../main.dart'; // Para acceder al databaseProvider

class SyncRepository {
  final AppDatabase _db;
  SyncRepository(this._db);

  Stream<List<SyncQueueItem>> watchQueue() {
    return (_db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> addItem(String type, String eid, String action, String data) async {
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: type,
        entityId: eid,
        action: action,
        payload: data,
        syncStatus: SyncStatus.pending,
      ),
    );
  }

  Future<void> updateStatus(int id, SyncStatus status) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(syncStatus: Value(status)),
    );
  }
}

final syncRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return SyncRepository(db);
});