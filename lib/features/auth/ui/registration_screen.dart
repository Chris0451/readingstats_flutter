import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class RegistrationScreen extends StatelessWidget {
  final VoidCallback onRegistered;
  final VoidCallback onLoginClick;
  const RegistrationScreen({super.key, required this.onRegistered, required this.onLoginClick});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final s = vm.reg;

    Widget usernameSupporting() {
      if (s.username.isEmpty) return const SizedBox.shrink();
      if (s.usernameAvailable == true) {
        return Text('Username disponibile', style: TextStyle(color: Theme.of(context).colorScheme.primary));
      }
      if (s.usernameAvailable == false) {
        return Text('Username non disponibile', style: TextStyle(color: Theme.of(context).colorScheme.error));
      }
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Registrazione', style: Theme.of(context).textTheme.headlineMedium)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(s.error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(decoration: const InputDecoration(labelText: 'Nome'), onChanged: vm.onNameChange),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Cognome'), onChanged: vm.onSurnameChange),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: vm.onUsernameChange,
            ),
            const SizedBox(height: 4),
            usernameSupporting(),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: vm.onEmailChange,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Password (min. 6 caratteri)'),
              obscureText: true,
              onChanged: vm.onPasswordChange,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Conferma password'),
              obscureText: true,
              onChanged: vm.onConfirmPasswordChange,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: s.canSubmit ? () async {
                await vm.submitRegister();
                if (vm.reg.success) onRegistered();
              } : null,
              child: s.isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrati'),
            ),
            TextButton(onPressed: onLoginClick, child: const Text('Hai già un account? Accedi')),
          ],
        ),
      ),
    );
  }
}
