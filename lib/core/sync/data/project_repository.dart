import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/local_database.dart';
import '../../../core/sync/domain/sync_status.dart';
import '../../../../main.dart';

class ProjectRepository {
  final AppDatabase _db;
  ProjectRepository(this._db);

  Stream<List<Project>> watchProjects() {
    return (_db.select(_db.projects)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
  }

  Future<void> createProject(Project project) async {
    await _db.transaction(() async {
      // 1. Guardar localmente
      await _db.into(_db.projects).insert(project);

      // 2. Registrar en cola de sincronización
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'project',
          entityId: project.id,
          action: 'create',
          payload: jsonEncode({
            'id': project.id,
            'name': project.name,
            'description': project.description,
            'location': project.location,
            'startDate': project.startDate.toIso8601String(),
            'status': project.status,
          }),
          syncStatus: SyncStatus.pending,
        ),
      );
    });
  }
}

final projectRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepository(db);
});