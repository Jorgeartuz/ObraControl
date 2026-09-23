import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';

class SyncEngine {
  /// Bucket de Supabase Storage para fotografías de registros diarios.
  /// Debe crearse manualmente en el proyecto Supabase (ver documentación).
  static const String photoStorageBucket = 'daily-record-photos';

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

        await processEntitySync(item);

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

  /// Procesa la sincronización específica para cada entidad (Create/Update/Delete)
  Future<void> processEntitySync(SyncQueueItem item) async {
    if (item.entityType == 'daily_record_photo') {
      await _processPhotoSync(item);
      return;
    }

    final client = Supabase.instance.client;
    final table = _remoteTableFor(item.entityType);

    if (item.action == 'delete') {
      await client.from(table).delete().eq('id', item.entityId);
    } else {
      final Map<String, dynamic> payload = jsonDecode(item.payload);
      await client.from(table).upsert(payload);
      await _markLocalSynced(item.entityType, item.entityId);
    }
  }

  /// Refleja localmente que una entidad ya fue confirmada por Supabase,
  /// para que la UI (StatusBadge) deje de mostrarla como "pendiente".
  ///
  /// Acotado a `machinery_usage_log` y `dump_truck_log`: son las únicas
  /// entidades nuevas de este macro-bloque que exponen su syncStatus en la
  /// UI. Las entidades preexistentes (project, daily_record, material_entry,
  /// material_exit, machinery) no se tocan aquí para no alterar su
  /// comportamiento actual fuera del alcance de este cambio.
  Future<void> _markLocalSynced(String entityType, String entityId) async {
    switch (entityType) {
      case 'machinery_usage_log':
        await (_db.update(
          _db.machineryUsageLogs,
        )..where((table) => table.id.equals(entityId))).write(
          const MachineryUsageLogsCompanion(syncStatus: Value(SyncStatus.synced)),
        );
      case 'dump_truck_log':
        await (_db.update(
          _db.dumpTruckLogs,
        )..where((table) => table.id.equals(entityId))).write(
          const DumpTruckLogsCompanion(syncStatus: Value(SyncStatus.synced)),
        );
    }
  }

  String _remoteTableFor(String entityType) {
    const tables = {
      'project': 'projects',
      'daily_record': 'daily_records',
      'material_entry': 'material_entries',
      'material_exit': 'material_exits',
      'machinery': 'machinery',
      'machinery_usage_log': 'machinery_usage_logs',
      'dump_truck_log': 'dump_truck_logs',
    };
    final table = tables[entityType];
    if (table == null) {
      throw UnsupportedError('Unsupported sync entity type: $entityType');
    }
    return table;
  }

  /// Sincroniza una fotografía de registro diario: sube el archivo local a
  /// Supabase Storage y solo entonces registra/actualiza la fila remota en
  /// `daily_record_photos`. La copia local NUNCA se elimina.
  ///
  /// Requiere que exista el bucket [photoStorageBucket] en Supabase Storage
  /// (ver documentación de configuración manual).
  Future<void> _processPhotoSync(SyncQueueItem item) async {
    final client = Supabase.instance.client;

    if (item.action == 'delete') {
      final Map<String, dynamic> payload = jsonDecode(item.payload);
      final storagePath = payload['storage_path'] as String?;
      if (storagePath != null) {
        await client.storage.from(photoStorageBucket).remove([storagePath]);
      }
      await client.from('daily_record_photos').delete().eq('id', item.entityId);
      return;
    }

    final photo = await (_db.select(
      _db.dailyRecordPhotos,
    )..where((table) => table.id.equals(item.entityId))).getSingleOrNull();
    if (photo == null) {
      // El registro/foto ya no existe localmente (se eliminó antes de sincronizar).
      return;
    }
    if (photo.syncStatus == SyncStatus.synced && photo.storagePath != null) {
      return; // Ya sincronizada: evita subirla dos veces.
    }

    final record = await (_db.select(
      _db.dailyRecords,
    )..where((table) => table.id.equals(photo.dailyRecordId))).getSingleOrNull();
    if (record == null) {
      throw StateError(
        'No se encontró el registro diario asociado a la fotografía ${photo.id}.',
      );
    }

    final file = File(photo.localPath);
    if (!await file.exists()) {
      throw StateError('El archivo local de la fotografía ${photo.id} ya no existe.');
    }

    final extension = p.extension(photo.localPath).isEmpty
        ? '.jpg'
        : p.extension(photo.localPath);
    final storagePath =
        'projects/${record.projectId}/daily_records/${photo.dailyRecordId}/${photo.id}$extension';

    await client.storage.from(photoStorageBucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    await client.from('daily_record_photos').upsert({
      'id': photo.id,
      'daily_record_id': photo.dailyRecordId,
      'storage_path': storagePath,
      'created_at': photo.createdAt.toIso8601String(),
      'created_by': photo.createdBy,
    });

    await (_db.update(
      _db.dailyRecordPhotos,
    )..where((table) => table.id.equals(photo.id))).write(
      DailyRecordPhotosCompanion(
        storagePath: Value(storagePath),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> restoreConnectivityFailures() async {
    final failedItems =
        await (_db.select(_db.syncQueue)..where(
              (table) => table.syncStatus.equals(SyncStatus.failed.index),
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
