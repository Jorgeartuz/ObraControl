import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'photo_storage_service.dart';

class DailyRecordRepository {
  DailyRecordRepository(this._db, this._syncAfterMutation);

  final AppDatabase _db;
  final Future<void> Function() _syncAfterMutation;
  final SupabaseClient _client = Supabase.instance.client;
  final PhotoStorageService _storage = PhotoStorageService();

  Stream<List<DailyRecord>> watchRecords(String projectId) =>
      (_db.select(_db.dailyRecords)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.desc(table.date)]))
          .watch();

  Stream<DailyRecord?> watchRecord(String id) => (_db.select(
    _db.dailyRecords,
  )..where((table) => table.id.equals(id))).watchSingleOrNull();

  Stream<List<DailyRecordPhoto>> watchPhotos(String recordId) =>
      (_db.select(_db.dailyRecordPhotos)
            ..where((table) => table.dailyRecordId.equals(recordId))
            ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
          .watch();

  Future<List<DailyRecordPhoto>> getPhotosForRecord(String recordId) =>
      (_db.select(
        _db.dailyRecordPhotos,
      )..where((table) => table.dailyRecordId.equals(recordId))).get();

  Future<void> saveCompleteRecord({
    required DailyRecord record,
    required List<String> tempPhotoPaths,
  }) async {
    final user = _requireUser();
    final recordToSave = record.createdBy == null
        ? record.copyWith(createdBy: Value(user.id))
        : record;
    await _db.transaction(() async {
      await _db.into(_db.dailyRecords).insert(recordToSave);
      await _queueRecord('create', recordToSave.id, recordToSave);
      for (final tempPath in tempPhotoPaths) {
        final permanentPath = await _storage.savePhotoPermanently(
          tempPath,
          record.id,
        );
        final photo = DailyRecordPhoto(
          id: '${record.id}_${DateTime.now().microsecondsSinceEpoch}',
          dailyRecordId: record.id,
          localPath: permanentPath,
          createdAt: DateTime.now(),
          createdBy: user.id,
          syncStatus: SyncStatus.pending,
        );
        await _db.into(_db.dailyRecordPhotos).insert(photo);
      }
    });
    await _syncAfterMutation();
  }

  Future<void> updateRecord(DailyRecord record) async {
    final existing = await (_db.select(
      _db.dailyRecords,
    )..where((table) => table.id.equals(record.id))).getSingleOrNull();
    final recordToSave = record.copyWith(
      createdAt: existing?.createdAt ?? record.createdAt,
      createdBy: Value(existing?.createdBy ?? record.createdBy),
      updatedAt: DateTime.now(),
    );
    await _db.transaction(() async {
      await _db.update(_db.dailyRecords).replace(recordToSave);
      await _queueRecord('update', recordToSave.id, recordToSave);
    });
    await _syncAfterMutation();
  }

  Future<void> deleteRecord(String id) async {
    await _db.transaction(() async {
      final photos = await (_db.select(
        _db.dailyRecordPhotos,
      )..where((table) => table.dailyRecordId.equals(id))).get();
      for (final photo in photos) {
        await (_db.delete(
          _db.dailyRecordPhotos,
        )..where((table) => table.id.equals(photo.id))).go();
      }
      await (_db.delete(
        _db.dailyRecords,
      )..where((table) => table.id.equals(id))).go();
      await _queueRecord('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> _queueRecord(String action, String id, DailyRecord? record) =>
      _queue(
        'daily_record',
        action,
        id,
        record == null ? {'id': id} : _recordPayload(record),
      );

  Future<void> _queue(
    String type,
    String action,
    String id,
    Map<String, dynamic> payload,
  ) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion.insert(
          entityType: type,
          entityId: id,
          action: action,
          payload: jsonEncode(payload),
          syncStatus: SyncStatus.pending,
        ),
      );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }

  Map<String, dynamic> _recordPayload(DailyRecord record) => {
    'id': record.id,
    'project_id': record.projectId,
    'date': record.date.toIso8601String(),
    'description': record.description,
    'observations': record.observations,
    'created_at': record.createdAt.toIso8601String(),
    'updated_at': record.updatedAt.toIso8601String(),
    'created_by': record.createdBy,
  };
}

final Provider<DailyRecordRepository> dailyRecordRepositoryProvider =
    Provider<DailyRecordRepository>(
      (ref) => DailyRecordRepository(
        ref.watch(databaseProvider),
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      ),
    );

final dailyRecordsProvider = StreamProvider.family<List<DailyRecord>, String>(
  (ref, projectId) =>
      ref.watch(dailyRecordRepositoryProvider).watchRecords(projectId),
);

final dailyRecordProvider = StreamProvider.family<DailyRecord?, String>(
  (ref, id) => ref.watch(dailyRecordRepositoryProvider).watchRecord(id),
);

final dailyRecordPhotosProvider =
    StreamProvider.family<List<DailyRecordPhoto>, String>(
      (ref, id) => ref.watch(dailyRecordRepositoryProvider).watchPhotos(id),
    );
