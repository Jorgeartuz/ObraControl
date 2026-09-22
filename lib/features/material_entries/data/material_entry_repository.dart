import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialEntryRepository {
  MaterialEntryRepository(this._db, this._syncAfterMutation);

  final AppDatabase _db;
  final Future<void> Function() _syncAfterMutation;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<MaterialEntry>> watchEntriesByProject(String projectId) =>
      (_db.select(_db.materialEntries)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.desc(table.date)]))
          .watch();

  Future<void> addEntry(MaterialEntry entry) async {
    final user = _requireUser();
    final entryToSave = entry.createdBy == null
        ? entry.copyWith(createdBy: Value(user.id))
        : entry;
    await _save(entryToSave, 'create', insert: true);
  }

  Future<void> updateEntry(MaterialEntry entry) async {
    _requireUser();
    final existing = await (_db.select(
      _db.materialEntries,
    )..where((table) => table.id.equals(entry.id))).getSingleOrNull();
    final entryToSave = existing == null
        ? entry
        : entry.copyWith(
            createdAt: existing.createdAt,
            createdBy: Value(existing.createdBy),
          );
    await _save(entryToSave, 'update');
  }

  Future<void> deleteEntry(String id) async {
    _requireUser();
    await _db.transaction(() async {
      await (_db.delete(
        _db.materialEntries,
      )..where((table) => table.id.equals(id))).go();
      await _queue('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> _save(
    MaterialEntry entry,
    String action, {
    bool insert = false,
  }) async {
    await _db.transaction(() async {
      if (insert) {
        await _db.into(_db.materialEntries).insert(entry);
      } else {
        await _db.update(_db.materialEntries).replace(entry);
      }
      await _queue(action, entry.id, entry);
    });
    await _syncAfterMutation();
  }

  Future<void> _queue(String action, String id, MaterialEntry? entry) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion.insert(
          entityType: 'material_entry',
          entityId: id,
          action: action,
          payload: jsonEncode(entry == null ? {'id': id} : _payload(entry)),
          syncStatus: SyncStatus.pending,
        ),
      );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }

  Map<String, dynamic> _payload(MaterialEntry entry) => {
    'id': entry.id,
    'project_id': entry.projectId,
    'date': entry.date.toIso8601String(),
    'material_name': entry.materialName,
    'quantity': entry.quantity,
    'unit': entry.unit,
    'supplier': entry.supplier,
    'observations': entry.observations,
    'created_at': entry.createdAt.toIso8601String(),
    'created_by': entry.createdBy,
  };
}

final Provider<MaterialEntryRepository> materialEntryRepositoryProvider =
    Provider<MaterialEntryRepository>(
      (ref) => MaterialEntryRepository(
        ref.watch(databaseProvider),
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      ),
    );

final materialEntriesStreamProvider =
    StreamProvider.family<List<MaterialEntry>, String>(
      (ref, projectId) => ref
          .watch(materialEntryRepositoryProvider)
          .watchEntriesByProject(projectId),
    );
