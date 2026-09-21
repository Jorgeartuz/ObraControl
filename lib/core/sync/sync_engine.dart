import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';

class SyncEngine {
  final AppDatabase _db;
  SyncEngine(this._db);

  /// Procesa todas las operaciones pendientes en la SyncQueue
  Future<void> processSyncQueue() async {
    final pendingItems = await (_db.select(_db.syncQueue)
          ..where((t) => t.syncStatus.equals(SyncStatus.pending.index)))
        .get();

    for (var item in pendingItems) {
      try {
        // Marcar como syncing
        await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
            .write(const SyncQueueCompanion(syncStatus: Value(SyncStatus.syncing)));

        if (item.entityType == 'project') {
          await processProjectSync(item);
        }

        // Marcar como sincronizado
        await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
            .write(const SyncQueueCompanion(syncStatus: Value(SyncStatus.synced)));
      } catch (e) {
        debugPrint("Sync Error [${item.entityType} ID: ${item.entityId}]: $e");
        
        // Marcar como fallido
        await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
            .write(SyncQueueCompanion(
          syncStatus: const Value(SyncStatus.failed),
          lastError: Value(e.toString()),
        ));
      }
    }
  }

  /// Procesa la sincronización específica para Proyectos (Create/Update/Delete)
  Future<void> processProjectSync(SyncQueueItem item) async {
    final client = Supabase.instance.client;

    if (item.action == 'delete') {
      // Borrado directo en Supabase usando el ID capturado en la cola
      await client.from('projects').delete().eq('id', item.entityId);
    } else {
      // Para create/update, usamos el payload JSON almacenado
      final Map<String, dynamic> payload = jsonDecode(item.payload);
      await client.from('projects').upsert(payload);
    }
  }
}