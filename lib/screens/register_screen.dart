import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Ortak
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController    = TextEditingController();

  // Sürücü
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();

  // Şirket
  final _companyNameController = TextEditingController();
  final _taxNumberController   = TextEditingController();
  final _authorizedNameController = TextEditingController(); // Yetkili ad soyad

  bool _isLoading   = false;
  bool _obscureText = true;
  bool _isCompany   = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _authorizedNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone    = _phoneController.text.trim();

    // Sürücü validasyon
    if (!_isCompany) {
      final firstName = _firstNameController.text.trim();
      final lastName  = _lastNameController.text.trim();
      if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty ||
          email.isEmpty || password.isEmpty) {
        _showSnackBar("Lütfen tüm alanları doldurun.");
        return;
      }
    }

    // Şirket validasyon
    if (_isCompany) {
      final companyName     = _companyNameController.text.trim();
      final taxNumber       = _taxNumberController.text.trim();
      final authorizedName  = _authorizedNameController.text.trim();
      if (companyName.isEmpty || taxNumber.isEmpty || authorizedName.isEmpty ||
          phone.isEmpty || email.isEmpty || password.isEmpty) {
        _showSnackBar("Lütfen tüm alanları doldurun.");
        return;
      }
      if (taxNumber.length < 10) {
        _showSnackBar("Vergi numarası 10 haneli olmalıdır.");
        return;
      }
    }

    if (password.length < 6) {
      _showSnackBar("Şifre en az 6 karakter olmalı.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final Map<String, dynamic> userData = {
        'email':     email,
        'phone':     phone,
        'role':      _isCompany ? 'company' : 'driver',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_isCompany) {
        userData['companyName']    = _companyNameController.text.trim();
        userData['taxNumber']      = _taxNumberController.text.trim();
        userData['authorizedName'] = _authorizedNameController.text.trim();
        // Yetkili adını firstName/lastName olarak da kaydet (profilde görünmesi için)
        final parts = _authorizedNameController.text.trim().split(' ');
        userData['firstName'] = parts.first;
        userData['lastName']  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      } else {
        userData['firstName'] = _firstNameController.text.trim();
        userData['lastName']  = _lastNameController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(initialIndex: _isCompany ? 1 : 0),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _showSnackBar("Bu e-posta adresi zaten kayıtlı.");
          break;
        case 'weak-password':
          _showSnackBar("Şifre çok zayıf, daha güçlü bir şifre girin.");
          break;
        case 'invalid-email':
          _showSnackBar("Geçersiz e-posta adresi.");
          break;
        default:
          _showSnackBar("Kayıt başarısız. Tekrar deneyin.");
      }
    } catch (e) {
      _showSnackBar("Bir hata oluştu. Tekrar deneyin.");
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── BAŞLIK ──
              const Text(
                "Hesap Oluştur",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isCompany ? "Şirket bilgilerinizi doldurun" : "Kişisel bilgilerinizi doldurun",
                style: const TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
              const SizedBox(height: 24),

              // ── ROL SEÇİCİ ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryWithOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _roleTab("Sürücü", Icons.local_shipping_outlined, !_isCompany)),
                    Expanded(child: _roleTab("Şirket", Icons.business_outlined, _isCompany)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── FORM ──
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
                  children: _isCompany
                      ? _buildCompanyFields()
                      : _buildDriverFields(),
                ),
              ),
              const SizedBox(height: 28),

              // ── KAYDET BUTONU ──
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
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
                      : const Text("Kaydı Tamamla", style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // ── GİRİŞ LİNKİ ──
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Zaten hesabın var mı?  ",
                      style: TextStyle(color: AppColors.textHint, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Giriş Yap",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── SÜRÜCÜ ALANLARI ──
  List<Widget> _buildDriverFields() {
    return [
      _buildField(
        controller: _firstNameController,
        hint: "Adınız",
        icon: Icons.person_outline_rounded,
        isFirst: true,
        keyboardType: TextInputType.name,
      ),
      _divider(),
      _buildField(
        controller: _lastNameController,
        hint: "Soyadınız",
        icon: Icons.person_outline_rounded,
        keyboardType: TextInputType.name,
      ),
      _divider(),
      _buildField(
        controller: _phoneController,
        hint: "Telefon No  (+90 5XX...)",
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
      _divider(),
      _buildField(
        controller: _emailController,
        hint: "E-posta",
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      _divider(),
      _buildField(
        controller: _passwordController,
        hint: "Şifre (en az 6 karakter)",
        icon: Icons.lock_outline,
        isPassword: true,
        isLast: true,
      ),
    ];
  }

  // ── ŞİRKET ALANLARI ──
  List<Widget> _buildCompanyFields() {
    return [
      _buildField(
        controller: _companyNameController,
        hint: "Şirket / Firma Adı",
        icon: Icons.apartment_outlined,
        isFirst: true,
        keyboardType: TextInputType.text,
      ),
      _divider(),
      _buildField(
        controller: _taxNumberController,
        hint: "Vergi Numarası (10 hane)",
        icon: Icons.receipt_long_outlined,
        keyboardType: TextInputType.number,
      ),
      _divider(),
      _buildField(
        controller: _authorizedNameController,
        hint: "Yetkili Adı Soyadı",
        icon: Icons.badge_outlined,
        keyboardType: TextInputType.name,
      ),
      _divider(),
      _buildField(
        controller: _phoneController,
        hint: "Telefon No  (+90 5XX...)",
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
      _divider(),
      _buildField(
        controller: _emailController,
        hint: "E-posta",
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      _divider(),
      _buildField(
        controller: _passwordController,
        hint: "Şifre (en az 6 karakter)",
        icon: Icons.lock_outline,
        isPassword: true,
        isLast: true,
      ),
    ];
  }

  // ── ROL SEKMESİ ──
  Widget _roleTab(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isCompany = (title == "Şirket")),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
              color: isSelected ? AppColors.textWhite : AppColors.textHint,
              size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.textWhite : AppColors.textHint,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── INPUT ALANI ──
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isFirst    = false,
    bool isLast     = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: isLast ? (_) => _register() : null,
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
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.primaryWithOpacity(0.4),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.primaryWithOpacity(0.3),
          fontSize: 14,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: AppColors.divider,
    indent: 20,
    endIndent: 20,
  );
}