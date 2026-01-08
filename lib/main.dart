import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure ile oluşan dosya
import 'screens/login_screen.dart'; 

void main() async {
  // Flutter widget sistemini ve Firebase'i başlatır
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
      theme: ThemeData(
        // Kurumsal Koyu Mavi Tema
        primaryColor: const Color(0xFF1B263B),
        scaffoldBackgroundColor: const Color(0xFF1B263B),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B263B),
          secondary: const Color(0xFFF3722C), // Turuncu detaylar için
        ),
      ),
      // Uygulama SplashScreen ile başlar
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 saniye bekledikten sonra LoginScreen'e yönlendirir
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Arka plan koyu mavi
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logonun assets klasöründe ve pubspec.yaml'da tanımlı olduğundan emin ol
            Image.asset(
              'assets/images/Trigo_logo.png', 
              width: 250,
              errorBuilder: (context, error, stackTrace) {
                // Eğer resim yüklenemezse ikon gösterir (Hata almamak için)
                return const Icon(Icons.local_shipping, size: 100, color: Colors.white);
              },
            ),
            const SizedBox(height: 20),
            
            const SizedBox(height: 30),
            // Alt kısımda yükleme halkası
            const CircularProgressIndicator(
              color: Color(0xFFF3722C), // Tirigo Turuncusu
            ),
          ],
        ),
      ),
    );
  }
}