import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/viewmodel/auth_view_model.dart';
import 'navigation/app_nav_host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AppNavHost(), // <-- AppNavHost ora sta SOTTO i provider
    );
  }
}
