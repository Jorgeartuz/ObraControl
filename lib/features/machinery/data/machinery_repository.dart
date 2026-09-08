import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';

class MachineryRepository {
  final AppDatabase _db;
  MachineryRepository(this._db);

  Stream<List<Machine>> watchMachinery(String projectId) {
    return (_db.select(_db.machinery)..where((t) => t.projectId.equals(projectId))).watch();
  }

  Future<void> addMachine(Machine machine) async {
    await _db.transaction(() async {
      // 1. Insertar en tabla de maquinaria
      await _db.into(_db.machinery).insert(machine);
      
      // 2. Insertar en cola de sincronización
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'machinery',
          entityId: machine.id,
          action: 'create',
          payload: jsonEncode({
            'id': machine.id,
            'projectId': machine.projectId,
            'name': machine.name,
            'type': machine.type,
          }),
          syncStatus: SyncStatus.pending, // Ahora sí lo reconocerá
        ),
      );
    });
  }
}

final machineryRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return MachineryRepository(db);
});

final machineryStreamProvider = StreamProvider.family<List<Machine>, String>((ref, projectId) {
  final repo = ref.watch(machineryRepositoryProvider);
  return repo.watchMachinery(projectId);
});