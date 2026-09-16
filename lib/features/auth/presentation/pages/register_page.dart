import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obrafcontrol_test/features/auth/data/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(_emailController.text, _passController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cuenta creada. Por favor verifica tu correo.")),
      );
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo electrónico"),
              validator: (v) => v!.contains('@') ? null : "Correo inválido",
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
              validator: (v) => (v?.length ?? 0) < 6 ? "Mínimo 6 caracteres" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirmar contraseña"),
              validator: (v) => v != _passController.text ? "Las contraseñas no coinciden" : null,
            ),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _register, child: const Text("CREAR CUENTA")),
          ],
        ),
      ),
    );
  }
}