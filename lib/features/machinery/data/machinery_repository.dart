import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MachineryRepository {
  MachineryRepository(this._db, this._syncAfterMutation);

  final AppDatabase _db;
  final Future<void> Function() _syncAfterMutation;
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Machine>> watchMachinery(String projectId) =>
      (_db.select(_db.machinery)
            ..where((table) => table.projectId.equals(projectId))
            ..orderBy([(table) => OrderingTerm.asc(table.name)]))
          .watch();

  Stream<Machine?> watchMachine(String id) => (_db.select(
    _db.machinery,
  )..where((table) => table.id.equals(id))).watchSingleOrNull();

  Future<void> addMachine(Machine machine) async {
    final user = _requireUser();
    await _save(
      machine.createdBy == null
          ? machine.copyWith(createdBy: Value(user.id))
          : machine,
      'create',
      insert: true,
    );
  }

  Future<void> updateMachine(Machine machine) async {
    _requireUser();
    final existing = await (_db.select(
      _db.machinery,
    )..where((table) => table.id.equals(machine.id))).getSingleOrNull();
    await _save(
      existing == null
          ? machine
          : machine.copyWith(createdBy: Value(existing.createdBy)),
      'update',
    );
  }

  Future<void> deleteMachine(String id) async {
    _requireUser();
    await _db.transaction(() async {
      await (_db.delete(
        _db.machinery,
      )..where((table) => table.id.equals(id))).go();
      await _queue('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> _save(
    Machine machine,
    String action, {
    bool insert = false,
  }) async {
    await _db.transaction(() async {
      if (insert) {
        await _db.into(_db.machinery).insert(machine);
      } else {
        await _db.update(_db.machinery).replace(machine);
      }
      await _queue(action, machine.id, machine);
    });
    await _syncAfterMutation();
  }

  Future<void> _queue(String action, String id, Machine? machine) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion.insert(
          entityType: 'machinery',
          entityId: id,
          action: action,
          payload: jsonEncode(machine == null ? {'id': id} : _payload(machine)),
          syncStatus: SyncStatus.pending,
        ),
      );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No hay un usuario autenticado.');
    return user;
  }

  Map<String, dynamic> _payload(Machine machine) => {
    'id': machine.id,
    'project_id': machine.projectId,
    'name': machine.name,
    'type': machine.type,
    'description': machine.description,
    'created_at': machine.createdAt.toIso8601String(),
    'created_by': machine.createdBy,
  };
}

final Provider<MachineryRepository> machineryRepositoryProvider =
    Provider<MachineryRepository>(
      (ref) => MachineryRepository(
        ref.watch(databaseProvider),
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      ),
    );

final machineryStreamProvider = StreamProvider.family<List<Machine>, String>(
  (ref, projectId) =>
      ref.watch(machineryRepositoryProvider).watchMachinery(projectId),
);

final machineProvider = StreamProvider.family<Machine?, String>(
  (ref, id) => ref.watch(machineryRepositoryProvider).watchMachine(id),
);
