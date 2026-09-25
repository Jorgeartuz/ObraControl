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
  final Future<void> Function() _syncAfterMutation;

  ProjectRepository(this._db, this._syncAfterMutation);

  // --- CRUD LOCAL ---
  /// Solo devuelve proyectos propios (`created_by = currentUserId`) o
  /// compartidos (`id` presente en `project_members` para `currentUserId`).
  /// El filtro se resuelve en SQLite (subquery correlacionada vía
  /// `existsQuery`), no en Dart: la UI nunca recibe filas ajenas para
  /// descartarlas después. El stream se re-emite automáticamente tanto si
  /// cambia `projects` como si cambia `project_members` (p. ej. tras un
  /// pull de membresías), porque ambas tablas forman parte de la consulta.
  Stream<List<Project>> watchProjects(String currentUserId) {
    final query = _db.select(_db.projects)
      ..where((p) => _ownsOrIsMember(p, currentUserId));
    return query.watch();
  }

  Stream<Project?> watchProject(String id, String currentUserId) {
    final query = _db.select(_db.projects)
      ..where((p) => p.id.equals(id) & _ownsOrIsMember(p, currentUserId));
    return query.watchSingleOrNull();
  }

  Expression<bool> _ownsOrIsMember(
    $ProjectsTable p,
    String currentUserId,
  ) {
    final isOwner = p.createdBy.equals(currentUserId);
    final isMember = existsQuery(
      _db.selectOnly(_db.projectMembers)
        ..addColumns([_db.projectMembers.id])
        ..where(
          _db.projectMembers.projectId.equalsExp(p.id) &
              _db.projectMembers.userId.equals(currentUserId),
        ),
    );
    return isOwner | isMember;
  }

  Future<void> createProject(Project project) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay un usuario autenticado para crear la obra.');
    }
    final projectToSave = project.createdBy == null
        ? project.copyWith(createdBy: Value(user.id))
        : project;

    await _db.transaction(() async {
      await _db.into(_db.projects).insert(projectToSave);
      await _logSync('create', projectToSave.id, projectToSave);
    });
    await _syncAfterMutation();
  }

  Future<void> updateProject(Project project) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.projects,
      )..where((table) => table.id.equals(project.id))).getSingleOrNull();
      final projectToSave = existing == null
          ? project
          : project.copyWith(createdBy: Value(existing.createdBy));
      await _db.update(_db.projects).replace(projectToSave);
      await _logSync('update', projectToSave.id, projectToSave);
    });
    await _syncAfterMutation();
  }

  Future<void> deleteProject(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
      await _logSync('delete', id, null);
    });
    await _syncAfterMutation();
  }

  Future<void> pushProject(Project project) async {
    final user = _client.auth.currentUser;
    final projectToPush = project.createdBy == null && user != null
        ? project.copyWith(createdBy: Value(user.id))
        : project;
    if (projectToPush.createdBy == null) {
      throw StateError(
        'No hay un usuario autenticado para sincronizar la obra.',
      );
    }
    await _client
        .from('projects')
        .upsert(_projectToSupabasePayload(projectToPush));
  }

  Future<void> pullProjects() async {
    final response = await _client.from('projects').select();
    final List<dynamic> data = response as List<dynamic>;

    await _db.transaction(() async {
      for (var row in data) {
        final id = row['id'] as String;

        // 1. Verificar si hay cambios locales pendientes usando una expresión compuesta
        final pending =
            await (_db.select(_db.syncQueue)..where(
                  (t) =>
                      t.entityId.equals(id) &
                      t.syncStatus.equals(SyncStatus.synced.index).not(),
                ))
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
        final local = await (_db.select(
          _db.projects,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _db.into(_db.projects).insertOnConflictUpdate(remote);
        }
      }
    });
  }

  // --- SYNC QUEUE LOGIC ---
  Future<void> _logSync(String action, String id, Project? project) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'project',
            entityId: id,
            action: action,
            payload: project != null
                ? jsonEncode(_projectToSupabasePayload(project))
                : jsonEncode({'id': id}),
            syncStatus: SyncStatus.pending,
          ),
        );
  }

  Map<String, dynamic> _projectToSupabasePayload(Project project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'location': project.location,
      'start_date': project.startDate.toIso8601String(),
      'status': project.status,
      'created_at': project.createdAt.toIso8601String(),
      'updated_at': project.updatedAt.toIso8601String(),
      'created_by': project.createdBy,
    };
  }
}

final Provider<ProjectRepository> projectRepositoryProvider =
    Provider<ProjectRepository>((ref) {
      final db = ref.watch(databaseProvider);
      return ProjectRepository(
        db,
        () => ref.read(projectSyncCoordinatorProvider).syncIfPossible(),
      );
    });
