import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialExitRepository {
  MaterialExitRepository(this._db, this._syncAfterMutation);

  final AppDatabase _db;
  final Future<void> Function() _syncAfterMutation;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<MaterialExit>> watchExitsByProject(String projectId) =>
      (_db.select(_db.materialExits)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.desc(table.date)]))
          .watch();

  Stream<MaterialExit?> watchExit(String id) => (_db.select(
    _db.materialExits,
  )..where((table) => table.id.equals(id))).watchSingleOrNull();

  Future<void> addExit(MaterialExit exit) async {
    final user = _requireUser();
    await _save(
      exit.createdBy == null ? exit.copyWith(createdBy: Value(user.id)) : exit,
      'create',
      insert: true,
    );
  }

  Future<void> updateExit(MaterialExit exit) async {
    _requireUser();
    final existing = await (_db.select(
      _db.materialExits,
    )..where((table) => table.id.equals(exit.id))).getSingleOrNull();
    await _save(
      existing == null
          ? exit
          : exit.copyWith(
              createdAt: existing.createdAt,
              createdBy: Value(existing.createdBy),
            ),
      'update',
    );
  }

  Future<void> deleteExit(String id) async {
    _requireUser();
    await _db.transaction(() async {
      await (_db.delete(
        _db.materialExits,
      )..where((table) => table.id.equals(id))).go();
      await _queue('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> _save(
    MaterialExit exit,
    String action, {
    bool insert = false,
  }) async {
    await _db.transaction(() async {
      if (insert) {
        await _db.into(_db.materialExits).insert(exit);
      } else {
        await _db.update(_db.materialExits).replace(exit);
      }
      await _queue(action, exit.id, exit);
    });
    await _syncAfterMutation();
  }

  Future<void> _queue(String action, String id, MaterialExit? exit) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion.insert(
          entityType: 'material_exit',
          entityId: id,
          action: action,
          payload: jsonEncode(exit == null ? {'id': id} : _payload(exit)),
          syncStatus: SyncStatus.pending,
        ),
      );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }

  Map<String, dynamic> _payload(MaterialExit exit) => {
    'id': exit.id,
    'project_id': exit.projectId,
    'date': exit.date.toIso8601String(),
    'material_name': exit.materialName,
    'quantity': exit.quantity,
    'unit': exit.unit,
    'destination': exit.destination,
    'responsible': exit.responsible,
    'observations': exit.observations,
    'created_at': exit.createdAt.toIso8601String(),
    'created_by': exit.createdBy,
  };
}

final Provider<MaterialExitRepository> materialExitRepositoryProvider =
    Provider<MaterialExitRepository>(
      (ref) => MaterialExitRepository(
        ref.watch(databaseProvider),
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      ),
    );

final materialExitStreamProvider =
    StreamProvider.family<List<MaterialExit>, String>(
      (ref, projectId) => ref
          .watch(materialExitRepositoryProvider)
          .watchExitsByProject(projectId),
    );

final materialExitProvider = StreamProvider.family<MaterialExit?, String>(
  (ref, id) => ref.watch(materialExitRepositoryProvider).watchExit(id),
);
