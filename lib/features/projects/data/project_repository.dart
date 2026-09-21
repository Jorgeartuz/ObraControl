import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/domain/sync_status.dart';
import 'package:obrafcontrol_test/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'; // <--- ESTO ES OBLIGATORIO para que el operador & funcione

class ProjectRepository {
  final AppDatabase _db;
  final SupabaseClient _client = Supabase.instance.client;

  ProjectRepository(this._db);

  // --- CRUD LOCAL ---
  Stream<List<Project>> watchProjects() => _db.select(_db.projects).watch();

  Future<void> createProject(Project project) async {
    await _db.transaction(() async {
      await _db.into(_db.projects).insert(project);
      await _logSync('create', project.id, project);
    });
  }

  Future<void> updateProject(Project project) async {
    await _db.transaction(() async {
      await _db.update(_db.projects).replace(project);
      await _logSync('update', project.id, project);
    });
  }

  Future<void> deleteProject(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
      await _logSync('delete', id, null);
    });
  }

  Future<void> pushProject(Project project) async {
  await _client.from('projects').upsert({
    'id': project.id,
    'name': project.name,
    'description': project.description,
    'location': project.location,
    'start_date': project.startDate.toIso8601String(),
    'status': project.status,
    'created_at': project.createdAt.toIso8601String(),
    'updated_at': project.updatedAt.toIso8601String(),
    'created_by': project.createdBy ?? _client.auth.currentUser!.id,
  });
}

Future<void> pullProjects() async {
    final response = await _client.from('projects').select();
    final List<dynamic> data = response as List<dynamic>;

    await _db.transaction(() async {
      for (var row in data) {
        final id = row['id'] as String;

        // 1. Verificar si hay cambios locales pendientes usando una expresión compuesta
        final pending = await (_db.select(_db.syncQueue)
              ..where((t) => t.entityId.equals(id) & t.syncStatus.equals(0)))
            .get();
        
        if (pending.isNotEmpty) continue;

        // 2. Construir objeto remoto
        final remote = Project(
          id: id,
          name: row['name'],
          description: row['description'],
          location: row['location'],
          startDate: DateTime.parse(row['start_date']),
          status: row['status'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          createdBy: row['created_by'],
        );

        // 3. Comparar y actualizar local
        final local = await (_db.select(_db.projects)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _db.into(_db.projects).insertOnConflictUpdate(remote);
        }
      }
    });
  }

  // --- SYNC QUEUE LOGIC ---
  Future<void> _logSync(String action, String id, Project? project) async {
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      entityType: 'project',
      entityId: id,
      action: action,
      payload: project != null ? jsonEncode(project.toJson()) : jsonEncode({'id': id}),
      syncStatus: SyncStatus.pending,
    ));
  }
}

final projectRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepository(db);
});