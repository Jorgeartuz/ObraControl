// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/app/app.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/sync_engine.dart';
import 'package:obrafcontrol_test/core/sync/project_sync_coordinator.dart';
import 'package:obrafcontrol_test/core/network/connectivity_service.dart';
import 'package:obrafcontrol_test/features/projects/data/project_repository.dart';

// Proveedor de la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Provider del motor de sincronización
final syncEngineProvider = Provider(
  (ref) => SyncEngine(ref.watch(databaseProvider)),
);

final Provider<ProjectSyncCoordinator> projectSyncCoordinatorProvider =
    Provider<ProjectSyncCoordinator>(
      (ref) => ProjectSyncCoordinator(
        ref.watch(syncEngineProvider),
        () => ref.read(projectRepositoryProvider).pullProjects(),
      ),
    );

final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env").catchError((e) => null);

  final url = dotenv.maybeGet('SUPABASE_URL');
  final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

  if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  runApp(const ProviderScope(child: AppInitializer()));
}

// Widget intermedio para escuchar cambios de red tras el inicio de la app
class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNow();
    });
  }

  Future<void> _syncNow() async {
    await ref.read(projectSyncCoordinatorProvider).syncIfPossible();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityStreamProvider, (previous, next) {
      if (next.value == NetworkStatus.online) {
        _syncNow();
      }
    });
    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.value?.session != null) {
        _syncNow();
      }
    });

    return const ObraControlApp();
  }
}
