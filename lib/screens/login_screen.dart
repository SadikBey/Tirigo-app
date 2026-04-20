import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ── ŞIFRE SIFIRLAMA ──
  void _showForgotPasswordSheet() {
    final resetCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          decoration: const BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWithOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Şifremi Unuttum", style: AppTextStyles.heading3),
                      Text("E-postanıza sıfırlama bağlantısı gönderilir",
                        style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: resetCtrl,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "E-posta adresiniz",
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (resetCtrl.text.trim().isEmpty) return;
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: resetCtrl.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _showSnackBar("Sıfırlama e-postası gönderildi! 📧", color: AppColors.success);
                    } catch (_) {
                      _showSnackBar("Bu e-posta adresi bulunamadı.");
                    }
                  },
                  child: const Text("Gönder", style: AppTextStyles.buttonPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GİRİŞ ──
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.exists && mounted) {
        final role = userDoc.get('role') ?? 'driver';
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: role == 'company' ? 1 : 0)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Yeni Firebase SDK'da invalid-credential kullanılıyor
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          _showSnackBar("Bu e-posta ile kayıtlı kullanıcı bulunamadı.");
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _showSnackBar("E-posta veya şifre hatalı.");
          break;
        case 'user-disabled':
          _showSnackBar("Bu hesap devre dışı bırakılmış.");
          break;
        case 'too-many-requests':
          _showSnackBar("Çok fazla deneme. Lütfen bekleyin.");
          break;
        default:
          _showSnackBar("Giriş başarısız. Tekrar deneyin.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── GOOGLE GİRİŞ ──
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        String? role = await _authService.getUserRole(user.uid);
        role = role ?? 'driver';
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: role == 'company' ? 1 : 0)),
          (route) => false,
        );
      } else {
        // Kullanıcı Google ekranını kapattı
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar("Google ile giriş başarısız. Tekrar deneyin.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color color = AppColors.error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── LOGO ──
              Center(
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/Trigo_logo.png',
                    width: 180,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_shipping_rounded,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── BAŞLIK ──
              const Text(
                "Hoş Geldiniz",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Hesabınıza giriş yapın",
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
              const SizedBox(height: 28),

              // ── GİRİŞ FORMU ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryWithOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _emailController,
                      hint: "E-posta",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isFirst: true,
                    ),
                    Divider(height: 1, color: AppColors.divider, indent: 20, endIndent: 20),
                    _buildInputField(
                      controller: _passwordController,
                      hint: "Şifre",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // ── ŞİFREMİ UNUTTUM ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _showForgotPasswordSheet,
                  child: const Text(
                    "Şifremi Unuttum?",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── GİRİŞ YAP BUTONU ──
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    disabledBackgroundColor: AppColors.secondaryWithOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.textWhite, strokeWidth: 2.5,
                          ),
                        )
                      : const Text("Giriş Yap", style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: 20),

              // ── AYRAÇ ──
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.primaryWithOpacity(0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      "veya",
                      style: TextStyle(
                        color: AppColors.primaryWithOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.primaryWithOpacity(0.15))),
                ],
              ),
              const SizedBox(height: 20),

              // ── GOOGLE GİRİŞ ──
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryWithOpacity(0.2), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: AppColors.backgroundCard,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_icon.png',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Google ile Giriş",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── HESAP OLUŞTUR ──
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Hesap Oluştur",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isFirst = false,
    bool isLast = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: isLast ? (_) => _login() : null,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryWithOpacity(0.5), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.primaryWithOpacity(0.4),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.primaryWithOpacity(0.3), fontSize: 15),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      ),
    );
  }
}