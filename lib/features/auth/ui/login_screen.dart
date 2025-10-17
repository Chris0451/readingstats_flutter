import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onRegisterClick;
  const LoginScreen({super.key, required this.onLoginSuccess, required this.onRegisterClick});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final state = vm.login;
    return Scaffold(
      appBar: AppBar(title: Text('Login', style: Theme.of(context).textTheme.headlineMedium)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(state.error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: vm.onLoginEmailChange,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: vm.onLoginPasswordChange,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.canSubmit ? () async {
                await vm.submitLogin();
                if (vm.login.success) onLoginSuccess();
              } : null,
              child: state.isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Accedi'),
            ),
            TextButton(onPressed: onRegisterClick, child: const Text('Non hai un account? Registrati')),
          ],
        ),
      ),
    );
  }
}
