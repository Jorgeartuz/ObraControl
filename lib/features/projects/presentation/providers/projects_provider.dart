import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/features/projects/data/project_repository.dart';

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects();
});

final projectStreamProvider = StreamProvider.family<Project?, String>((
  ref,
  projectId,
) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProject(projectId);
});
