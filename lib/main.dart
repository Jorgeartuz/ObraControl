import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/database/local_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de .env (opcional si el archivo no existe aún para evitar crash)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Preparación para Supabase (Sin credenciales reales no inicializa, evitando errores)
  final url = dotenv.maybeGet('SUPABASE_URL');
  final anon = dotenv.maybeGet('SUPABASE_ANON_KEY');

  if (url != null && anon != null && url.isNotEmpty && anon.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: anon);
  }

  runApp(const ProviderScope(child: ObraControlApp()));
}