import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/features/auth/presentation/pages/login_page.dart';
import 'package:obrafcontrol_test/features/home/presentation/pages/home_page.dart';
import 'package:obrafcontrol_test/main.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Las rutas empujadas con Navigator.push (Mis obras, detalle, formularios)
    // viven POR ENCIMA de AuthGate, así que cambiar lo que AuthGate muestra
    // no las cierra: tras un logout (o un cambio de cuenta) seguirían
    // visibles pantallas del usuario anterior. Al cambiar la identidad se
    // vuelve a la raíz, para que solo quede visible lo que AuthGate decide.
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    });

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session =
            snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}