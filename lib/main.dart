import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/viewmodel/auth_view_model.dart';
import 'navigation/app_nav_host.dart';

import 'features/catalog/data/books_api.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const kBooksApiKey = String.fromEnvironment('BOOKS_API_KEY', defaultValue: '');
const kAndroidCertSha1 = String.fromEnvironment('ANDROID_CERT_SHA1', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final pkg = await PackageInfo.fromPlatform();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
        Provider<BooksApi>(
          create: (_) => BooksApi(
            apiKey: kBooksApiKey,
            androidPackage: pkg.packageName,
            androidCert: kAndroidCertSha1.replaceAll(':', '').toUpperCase(),
          ),
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
