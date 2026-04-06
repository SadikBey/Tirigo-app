import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/constants.dart';
import '../services/auth_service.dart';
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
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Şifremi Unuttum",
            style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Şifre sıfırlama bağlantısı için e-posta adresinizi girin."),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                hintText: "E-posta",
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Vazgeç", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: resetEmailController.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showSnackBar("Sıfırlama e-postası gönderildi!", color: AppColors.success);
                } catch (_) {
                  _showSnackBar("Hata: E-posta adresi bulunamadı.");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Gönder", style: TextStyle(color: AppColors.textWhite)),
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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.exists && mounted) {
        String role = userDoc.get('role') ?? 'driver';
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: role == 'company' ? 1 : 0)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.code == 'user-not-found'
          ? "Kullanıcı bulunamadı."
          : e.code == 'wrong-password'
              ? "Hatalı şifre."
              : "Giriş başarısız.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        String? role = await _authService.getUserRole(user.uid);
        role = role ?? 'driver';
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: role == 'company' ? 1 : 0)),
          (route) => false,
        );
      }
    } catch (_) {
      _showSnackBar("Google giriş başarısız.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color color = AppColors.error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Hero(tag: 'logo', child: Image.asset('assets/images/Trigo_logo.png', width: 220)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: AppColors.primaryWithOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    _buildTextField(controller: _emailController, hint: "E-posta", icon: Icons.email_outlined),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.divider)),
                    _buildTextField(controller: _passwordController, hint: "Şifre", icon: Icons.lock_outline, isPassword: true, obscureText: _obscureText, onSuffixTap: () => setState(() => _obscureText = !_obscureText)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text('Şifremi Unuttum?', style: TextStyle(color: AppColors.primaryWithOpacity(0.7), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, elevation: 4, shadowColor: AppColors.secondaryWithOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: AppColors.textWhite) : const Text('Giriş Yap', style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Divider(color: AppColors.primaryWithOpacity(0.2))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('veya', style: TextStyle(color: AppColors.primaryWithOpacity(0.5)))),
                Expanded(child: Divider(color: AppColors.primaryWithOpacity(0.2))),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 58,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primaryWithOpacity(0.2), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 22),
                    const SizedBox(width: 12),
                    Text('Google ile Giriş', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 58,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Hesap Oluştur', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool obscureText = false, VoidCallback? onSuffixTap}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryWithOpacity(0.6)),
        suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryWithOpacity(0.4)), onPressed: onSuffixTap) : null,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.primaryWithOpacity(0.3)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}