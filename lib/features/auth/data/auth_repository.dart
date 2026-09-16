import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      debugPrint('--- SUPABASE SIGN IN ERROR ---');
      debugPrint('Message: ${e.message}');
      debugPrint('StatusCode: ${e.statusCode}');
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      debugPrint('--- UNEXPECTED SIGN IN ERROR ---');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      throw "Ocurrió un error inesperado.";
    }
  }

  Future<void> signUp(String fullName, String email, String password) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } on AuthException catch (e) {
      debugPrint('--- SUPABASE AUTH ERROR ---');
      debugPrint('Message: ${e.message}');
      debugPrint('StatusCode: ${e.statusCode}');
      throw _handleAuthError(e);
    } catch (e, stackTrace) {
      debugPrint('--- UNEXPECTED AUTH ERROR ---');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      throw "Ocurrió un error inesperado.";
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  String _handleAuthError(AuthException e) {
    if (e.message.contains("Invalid login credentials")) {
      return "Correo o contraseña incorrectos.";
    }
    if (e.message.contains("User already registered")) {
      return "Ya existe una cuenta con este correo.";
    }
    if (e.message.contains("Password should be at least 6 characters")) {
      return "La contraseña debe tener al menos 6 caracteres.";
    }
    return "Error: ${e.message}";
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
