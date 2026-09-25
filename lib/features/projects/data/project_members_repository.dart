import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/main.dart';

/// Espejo local de `public.project_members`. Solo pull (lectura remota ->
/// local); no hay escritura local desde la app todavía (compartir/gestionar
/// miembros queda fuera de alcance de este bloque).
class ProjectMembersRepository {
  final AppDatabase _db;
  final SupabaseClient _client = Supabase.instance.client;

  ProjectMembersRepository(this._db);

  /// Trae las membresías visibles para el usuario autenticado.
  ///
  /// No se aplica ningún filtro adicional en el cliente: la policy RLS de
  /// `project_members` (`using (has_project_access(project_id))`, definida
  /// en el Bloque 1A) ya garantiza que Supabase solo devuelve las filas de
  /// proyectos a los que el usuario tiene acceso (como owner o como
  /// member) — exactamente "las membresías que el usuario autenticado
  /// puede consultar".
  Future<void> pullProjectMembers() async {
    final response = await _client.from('project_members').select();
    final List<dynamic> data = response as List<dynamic>;

    await _db.transaction(() async {
      for (final row in data) {
        await _db.into(_db.projectMembers).insertOnConflictUpdate(
              ProjectMembersCompanion.insert(
                id: row['id'] as String,
                projectId: row['project_id'] as String,
                userId: row['user_id'] as String,
                role: row['role'] as String,
                invitedBy: Value(row['invited_by'] as String?),
                createdAt: Value(DateTime.parse(row['created_at'] as String)),
              ),
            );
      }
    });
  }
}

final projectMembersRepositoryProvider = Provider<ProjectMembersRepository>((ref) {
  return ProjectMembersRepository(ref.watch(databaseProvider));
});
