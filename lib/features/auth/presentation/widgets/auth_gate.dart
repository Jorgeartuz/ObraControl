import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:obrafcontrol_test/features/auth/presentation/pages/login_page.dart';
import 'package:obrafcontrol_test/features/projects/presentation/pages/projects_list_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session =
            snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const ProjectsListPage();
        }
        return const LoginPage();
      },
    );
  }
}