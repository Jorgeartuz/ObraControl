import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'photo_storage_service.dart';

class DailyRecordRepository {
  final AppDatabase _db;
  final PhotoStorageService _storage = PhotoStorageService();
  DailyRecordRepository(this._db);

  Stream<List<DailyRecord>> watchRecords(String projectId) {
    return (_db.select(_db.dailyRecords)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<DailyRecordPhoto>> getPhotosForRecord(String recordId) async {
    return await (_db.select(_db.dailyRecordPhotos)..where((t) => t.dailyRecordId.equals(recordId))).get();
  }

  Future<void> saveCompleteRecord({
    required DailyRecord record,
    required List<String> tempPhotoPaths,
  }) async {
    await _db.transaction(() async {
      // 1. Guardar Registro Diario
      await _db.into(_db.dailyRecords).insert(record);
      
      // 2. Guardar en SyncQueue (Registro)
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
        entityType: 'daily_record',
        entityId: record.id,
        action: 'create',
        payload: jsonEncode({
          'id': record.id,
          'projectId': record.projectId,
          'description': record.description,
          'date': record.date.toIso8601String(),
        }),
        syncStatus: SyncStatus.pending,
      ));

      // 3. Procesar Fotos
      for (var tempPath in tempPhotoPaths) {
        final permPath = await _storage.savePhotoPermanently(tempPath, record.id);
        final photoId = "${record.id}_${DateTime.now().millisecondsSinceEpoch}";
        
        await _db.into(_db.dailyRecordPhotos).insert(DailyRecordPhoto(
          id: photoId,
          dailyRecordId: record.id,
          localPath: permPath,
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ));

        // SyncQueue (Foto)
        await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          entityType: 'daily_record_photo',
          entityId: photoId,
          action: 'create',
          payload: jsonEncode({'id': photoId, 'recordId': record.id, 'path': permPath}),
          syncStatus: SyncStatus.pending,
        ));
      }
    });
  }
}

final dailyRecordRepositoryProvider = Provider((ref) => DailyRecordRepository(ref.watch(databaseProvider)));