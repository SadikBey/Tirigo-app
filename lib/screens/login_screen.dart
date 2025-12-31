import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase paketi
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller'lar ve Durum Değişkenleri
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Giriş yaparken çark dönsün mü?
  bool _obscureText = true; // Şifre gizli mi?

  // --- GİRİŞ YAPMA FONKSİYONU ---
  Future<void> _login() async {
    // Boş alan kontrolü
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() => _isLoading = true); // Yükleme başladı

    try {
      // Firebase Auth ile Giriş
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Başarılıysa: Ana sayfaya yönlendir ve geri dönüşü engelle
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Firebase Hatalarını Yakala
      String errorMsg = "Giriş başarısız.";
      if (e.code == 'user-not-found') errorMsg = "Kullanıcı bulunamadı.";
      else if (e.code == 'wrong-password') errorMsg = "Hatalı şifre.";
      else if (e.code == 'invalid-email') errorMsg = "Geçersiz e-posta adresi.";
      
      _showSnackBar(errorMsg);
    } catch (e) {
      _showSnackBar("Bir hata oluştu: $e");
    } finally {
      // İşlem bittiğinde (başarılı veya başarısız) yüklemeyi durdur
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hata mesajı göstermek için yardımcı fonksiyon
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B263B), // Tasarımdaki Koyu Mavi
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Logo (Yolun doğruluğundan emin ol)
                Image.asset('assets/images/Trigo_logo2.png', width: 220),
                const SizedBox(height: 10),
                const Text(
                  'Tirigo\'ya Hoş Geldiniz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 40),

                // Giriş Formu (Beyaz Kart)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // E-posta
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1B263B)),
                          hintText: 'E-posta',
                          border: InputBorder.none,
                        ),
                      ),
                      const Divider(),
                      // Şifre
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1B263B)),
                          hintText: 'Şifre',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Giriş Yap Butonu
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login, // Yükleme varken butonu kapat
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3722C), // Turuncu
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Şifre sıfırlama işlemi buraya gelecek
                  },
                  child: const Text('Şifremi Unuttum', style: TextStyle(color: Colors.white70)),
                ),

                const SizedBox(height: 10),
                // Kayıt Ol Butonu
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kayıt Ol', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}