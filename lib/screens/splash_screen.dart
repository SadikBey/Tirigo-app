import 'package:flutter/material.dart';
import 'login_screen.dart'; // Giriş ekranına yönlendirmek için

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 saniye bekleyip LoginScreen'e gider
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B263B), // Lacivert arka plan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BÜYÜK LOGO
            Image.asset(
              'assets/images/Trigo_logo.png',
              width: 200, // Boyutu ihtiyacına göre ayarla
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Color(0xFFF3722C), // Tirigo Turuncusu yükleme ikonu
            ),
          ],
        ),
      ),
    );
  }
}