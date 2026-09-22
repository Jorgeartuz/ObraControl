import 'dart:async';
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
    final pendingItems = await (_db.select(
      _db.syncQueue,
    )..where((t) => t.syncStatus.equals(SyncStatus.pending.index))).get();

    for (var item in pendingItems) {
      try {
        // Marcar como syncing
        await (_db.update(
          _db.syncQueue,
        )..where((t) => t.id.equals(item.id))).write(
          const SyncQueueCompanion(syncStatus: Value(SyncStatus.syncing)),
        );

        if (item.entityType != 'project') {
          throw UnsupportedError(
            'Unsupported sync entity type: ${item.entityType}',
          );
        }
        await processProjectSync(item);

        // Marcar como sincronizado
        await (_db.update(
          _db.syncQueue,
        )..where((t) => t.id.equals(item.id))).write(
          const SyncQueueCompanion(syncStatus: Value(SyncStatus.synced)),
        );
      } catch (e) {
        debugPrint("Sync Error [${item.entityType} ID: ${item.entityId}]: $e");

        final isConnectivityError = _isConnectivityError(e);
        await (_db.update(
          _db.syncQueue,
        )..where((t) => t.id.equals(item.id))).write(
          SyncQueueCompanion(
            syncStatus: Value(
              isConnectivityError ? SyncStatus.pending : SyncStatus.failed,
            ),
            lastError: Value(e.toString()),
            retryCount: Value(item.retryCount + 1),
          ),
        );
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

  Future<void> restoreConnectivityFailures() async {
    final failedItems =
        await (_db.select(_db.syncQueue)..where(
              (table) =>
                  table.entityType.equals('project') &
                  table.syncStatus.equals(SyncStatus.failed.index),
            ))
            .get();

    for (final item in failedItems) {
      if (!_isConnectivityErrorMessage(item.lastError)) continue;

      await (_db.update(
        _db.syncQueue,
      )..where((table) => table.id.equals(item.id))).write(
        const SyncQueueCompanion(syncStatus: Value(SyncStatus.pending)),
      );
    }
  }

  bool _isConnectivityError(Object error) {
    return error is TimeoutException ||
        _isConnectivityErrorMessage(error.toString());
  }

  bool _isConnectivityErrorMessage(String? message) {
    if (message == null) return false;

    final normalized = message.toLowerCase();
    return normalized.contains('socketexception') ||
        normalized.contains('timeoutexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection closed') ||
        normalized.contains('clientexception');
  }
}
