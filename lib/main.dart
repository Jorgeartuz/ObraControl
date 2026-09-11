// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/database/local_database.dart';

// Proveedor global de la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Archivo .env no encontrado, continuando sin él.");
  }

  // 2. Inicializar Supabase
  final url = dotenv.maybeGet('SUPABASE_URL');
  final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

  if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // 3. Ejecutar la aplicación
  runApp(
    const ProviderScope(
      child: ObraControlApp(),
    ),
  );
}