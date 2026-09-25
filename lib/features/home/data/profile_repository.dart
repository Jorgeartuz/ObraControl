import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/main.dart';

class Profile {
  final String id;
  final String? fullName;

  const Profile({required this.id, this.fullName});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
    );
  }
}

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

/// Perfil del usuario autenticado, reactivo a `currentUserIdProvider`: al
/// depender de él vía `ref.watch` (no `ref.read`), este `FutureProvider` se
/// vuelve a ejecutar automáticamente cada vez que cambia el id del usuario
/// (login, logout, cambio de cuenta), en vez de conservar indefinidamente
/// el perfil del usuario anterior como ocurría antes de este bloque.
final currentProfileProvider = FutureProvider<Profile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});
