import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/core/presentation/theme/app_theme.dart';
import 'package:obrafcontrol_test/features/auth/data/auth_repository.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(_emailController.text, _passController.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.architecture, size: 80, color: AppColors.primary),
            const Text("ObraControl", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Correo")),
            const SizedBox(height: 16),
            TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña")),
            const SizedBox(height: 24),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: const Text("INICIAR SESIÓN")),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text("Crear cuenta")),
          ],
        ),
      ),
    );
  }
}