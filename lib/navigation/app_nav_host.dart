import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/viewmodel/auth_view_model.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/registration_screen.dart';

// Placeholder comuni
class _CenteredPage extends StatelessWidget {
  final String title;
  const _CenteredPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: vm.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 2; // Home di default

  final _pages = const [
    _CenteredPage('Scaffali'),
    _CenteredPage('Catalogo'),
    _CenteredPage('Home'),
    _CenteredPage('Profilo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Scaffali'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Catalogo'),
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
        ],
      ),
    );
  }
}

class AppNavHost extends StatelessWidget {
  const AppNavHost({super.key});

  @override
  Widget build(BuildContext context) {
    // Prendi il VM dal Provider già messo in main.dart
    final vm = context.read<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: vm.authState,
      builder: (context, snap) {
        final isAuth = snap.data != null;

        return Navigator(
          pages: [
            if (!isAuth)
              MaterialPage(
                child: LoginScreen(
                  onLoginSuccess: () {}, // lo stream porterà a MainShell
                  onRegisterClick: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RegistrationScreen(
                        onRegistered: () => Navigator.of(context).pop(),
                        onLoginClick: () => Navigator.of(context).pop(),
                      ),
                    ));
                  },
                ),
              ),
            if (isAuth) const MaterialPage(child: MainShell()),
          ],
          onPopPage: (route, result) => route.didPop(result),
        );
      },
    );
  }
}