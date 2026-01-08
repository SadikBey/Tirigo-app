import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Marka Renklerin
  final Color brandOrange = const Color(0xFFF3722C);
  final Color brandNavy = const Color(0xFF1B263B);
  final Color backgroundColor = const Color(0xFFF0F4F8);

  void _showForgotPasswordDialog() {
    final TextEditingController _resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Şifremi Unuttum", style: TextStyle(color: brandNavy, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Şifre sıfırlama bağlantısı için e-posta adresinizi girin."),
            const SizedBox(height: 15),
            TextField(
              controller: _resetEmailController,
              decoration: InputDecoration(
                hintText: "E-posta",
                prefixIcon: Icon(Icons.email_outlined, color: brandNavy),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Vazgeç", style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () async {
              if (_resetEmailController.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: _resetEmailController.text.trim());
                  Navigator.pop(context);
                  _showSnackBar("Sıfırlama e-postası gönderildi!", color: Colors.green);
                } catch (e) {
                  _showSnackBar("Hata: E-posta adresi bulunamadı.");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: brandOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Gönder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists && mounted) {
        String role = userDoc.get('role') ?? 'driver';
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(initialIndex: (role == 'company' ? 1 : 0))),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.code == 'user-not-found' ? "Kullanıcı bulunamadı." : e.code == 'wrong-password' ? "Hatalı şifre." : "Giriş başarısız.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo Alanı
              Hero(tag: 'logo', child: Image.asset('assets/images/Trigo_logo.png', width: 220)),
              const SizedBox(height: 40),
              
              // Giriş Kartı
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: brandNavy.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(controller: _emailController, hint: "E-posta", icon: Icons.email_outlined),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFF0F4F8))),
                    _buildTextField(
                      controller: _passwordController,
                      hint: "Şifre",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscureText,
                      onSuffixTap: () => setState(() => _obscureText = !_obscureText),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Şifremi Unuttum
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text('Şifremi Unuttum?', style: TextStyle(color: brandNavy.withOpacity(0.7), fontWeight: FontWeight.w600)),
                ),
              ),
              
              const SizedBox(height: 20),

              // Giriş Yap Butonu
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    elevation: 4,
                    shadowColor: brandOrange.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 16),

              // Kayıt Ol Butonu
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: brandNavy, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Hesap Oluştur', style: TextStyle(color: brandNavy, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: brandNavy, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: brandNavy.withOpacity(0.6)),
        suffixIcon: isPassword 
            ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: brandNavy.withOpacity(0.4)), onPressed: onSuffixTap) 
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: brandNavy.withOpacity(0.3)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}