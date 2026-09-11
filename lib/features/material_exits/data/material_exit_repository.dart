import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';

class MaterialExitRepository {
  final AppDatabase _db;
  MaterialExitRepository(this._db);

  // Stream para observar las salidas de un proyecto específico
  Stream<List<MaterialExit>> watchExitsByProject(String projectId) {
    return (_db.select(_db.materialExits)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  // Método para guardar una salida y registrarla en la cola de sincronización
  Future<void> addExit(MaterialExit exit) async {
    await _db.transaction(() async {
      // 1. Guardar localmente en tabla materialExits
      await _db.into(_db.materialExits).insert(exit);
      
      // 2. Registrar operación pendiente en SyncQueue
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'material_exit',
          entityId: exit.id,
          action: 'create',
          payload: jsonEncode({
            'id': exit.id,
            'projectId': exit.projectId,
            'materialName': exit.materialName,
            'quantity': exit.quantity,
            'unit': exit.unit,
            'destination': exit.destination,
            'date': exit.date.toIso8601String(),
          }),
          syncStatus: SyncStatus.pending,
        ),
      );
    });
  }
}

// Proveedor del Repositorio
final materialExitRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return MaterialExitRepository(db);
});

// Provider para escuchar el stream de datos en tiempo real
final materialExitStreamProvider = StreamProvider.family<List<MaterialExit>, String>((ref, projectId) {
  final repo = ref.watch(materialExitRepositoryProvider);
  return repo.watchExitsByProject(projectId);
});