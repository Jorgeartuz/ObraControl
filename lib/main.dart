// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/app/app.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';
import 'package:obrafcontrol_test/core/sync/sync_engine.dart';
import 'package:obrafcontrol_test/core/network/connectivity_service.dart';
import 'package:obrafcontrol_test/features/projects/data/project_repository.dart';

// Proveedor de la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Provider del motor de sincronización
final syncEngineProvider = Provider((ref) => SyncEngine(
      ref.watch(databaseProvider),
    ));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env").catchError((e) => null);

  final url = dotenv.maybeGet('SUPABASE_URL');
  final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

  if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  runApp(
    const ProviderScope(
      child: AppInitializer(),
    ),
  );
}

// Widget intermedio para escuchar cambios de red tras el inicio de la app
class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar cambios de conectividad
    ref.listen(connectivityStreamProvider, (prev, next) async {
 if (next.value == NetworkStatus.online && Supabase.instance.client.auth.currentUser != null) {
    final syncEngine = ref.read(syncEngineProvider);
    final projectRepo = ref.read(projectRepositoryProvider);
    
    // Secuencia obligatoria
    await syncEngine.processSyncQueue();
    await projectRepo.pullProjects();
  }
});

    return const ObraControlApp();
  }
}