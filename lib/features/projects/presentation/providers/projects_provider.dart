import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/features/projects/data/project_repository.dart';
import 'package:obrafcontrol_test/main.dart';

/// Depende de `currentUserIdProvider` para que, al cambiar de usuario
/// (login/logout/cambio de cuenta), el stream se vuelva a construir con el
/// nuevo id y deje de mostrar los proyectos del usuario anterior. Sin
/// sesión, no hay usuario para el cual filtrar: se expone una lista vacía
/// en vez de propagar datos sin filtrar.
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects(userId);
});

final projectStreamProvider = StreamProvider.family<Project?, String>((
  ref,
  projectId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProject(projectId, userId);
});
