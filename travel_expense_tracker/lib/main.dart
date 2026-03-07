import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/trip_provider.dart';
import 'screens/home.dart';
import 'screens/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => TripProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Expense Tracker',
      theme: AppTheme.theme,
      home: FirebaseAuth.instance.currentUser != null
          ? const HomeScreen()
          : const AuthScreen(),
    );
  }
}