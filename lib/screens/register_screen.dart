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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _isCompany = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty || _emailController.text.isEmpty ||
        _passwordController.text.isEmpty || (_isCompany && _companyNameController.text.isEmpty)) {
      _showMessage("Lütfen tüm alanları doldurun.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _isCompany ? 'company' : 'driver',
        'companyName': _isCompany ? _companyNameController.text.trim() : null,
        'createdAt': DateTime.now(),
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.code == 'email-already-in-use' ? "Bu e-posta zaten kayıtlı." : e.code == 'weak-password' ? "Şifre çok zayıf." : "Hata oluştu.");
    } catch (e) {
      _showMessage("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                Text(
                  _isCompany ? 'Şirket / İş Veren Kaydı' : 'Sürücü Kaydı',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.textWhite),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(child: _roleOption("Şoför", Icons.local_shipping, !_isCompany)),
                      Expanded(child: _roleOption("Şirket", Icons.business, _isCompany)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      if (_isCompany) ...[
                        _buildField(_companyNameController, 'Şirket / Firma Adı', Icons.apartment),
                        const Divider(),
                      ],
                      _buildField(_firstNameController, 'Adınız', Icons.person_outline),
                      const Divider(),
                      _buildField(_lastNameController, 'Soyadınız', Icons.person_outline),
                      const Divider(),
                      _buildField(_phoneController, 'Telefon No', Icons.phone_android, isPhone: true),
                      const Divider(),
                      _buildField(_emailController, 'E-posta', Icons.email_outlined),
                      const Divider(),
                      _buildField(_passwordController, 'Şifre', Icons.lock_outline, isPass: true),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading ? const CircularProgressIndicator(color: AppColors.textWhite) : const Text('Kaydı Tamamla', style: AppTextStyles.buttonPrimary),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleOption(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isCompany = (title == "Şirket")),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.textWhite : AppColors.textHint, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? AppColors.textWhite : AppColors.textHint, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isPass = false, bool isPhone = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass ? _obscureText : false,
      keyboardType: isPhone ? TextInputType.phone : (isPass ? TextInputType.text : TextInputType.emailAddress),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary),
        hintText: hint,
        border: InputBorder.none,
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
    );
  }
}