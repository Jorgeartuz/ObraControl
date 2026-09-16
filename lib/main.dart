// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/app/app.dart';
import 'package:obrafcontrol_test/core/database/local_database.dart';

// Proveedor global de la base de datos (Drift)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 // 1. Cargar variables de entorno
  await dotenv.load(fileName: ".env").catchError((e) {
    debugPrint("Error cargando .env: $e");
    return null;
  });

  // 2. Obtener y verificar llaves
  final url = dotenv.maybeGet('SUPABASE_URL');
  final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

debugPrint("Supabase URL: $url"); // <- REVISA ESTO EN TU CONSOLA
  debugPrint("Supabase Key: ${anonKey != null ? 'Presente' : 'Ausente'}");

  // 3. Inicializar SOLAMENTE si hay datos
  if (url != null && url.isNotEmpty) {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey ?? '',
    );
    debugPrint("Supabase inicializado correctamente");
  } else {
    debugPrint("ADVERTENCIA: Supabase NO inicializado por falta de variables");
  }

  runApp(const ProviderScope(child: ObraControlApp()));
}