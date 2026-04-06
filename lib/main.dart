import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/constants.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TirigoApp());
}

class TirigoApp extends StatelessWidget {
  const TirigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tirigo',
      theme: AppTheme.lightTheme, // ✅ Merkezi tema
      home: const SplashScreen(),
    );
  }
}

// SplashScreen artık screens/splash_screen.dart dosyasından geliyor.