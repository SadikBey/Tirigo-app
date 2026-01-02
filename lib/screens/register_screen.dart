import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _companyNameController = TextEditingController(); // Şirket adı için

  bool _isLoading = false;
  bool _obscureText = true;
  
  // ROL SEÇİMİ İÇİN DEĞİŞKENLER
  // true ise Şirket (İş Veren), false ise Şoför
  bool _isCompany = false; 

  Future<void> _register() async {
    if (_firstNameController.text.isEmpty || 
        _lastNameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        (_isCompany && _companyNameController.text.isEmpty)) { // Şirket seçiliyse ad kontrolü
      _showMessage("Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- Veritabanına Kayıt (Dinamik Rol ile) ---
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _isCompany ? 'company' : 'driver', // Seçime göre kayıt
        'companyName': _isCompany ? _companyNameController.text.trim() : null,
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Hata oluştu.";
      if (e.code == 'email-already-in-use') message = "Bu e-posta zaten kayıtlı.";
      else if (e.code == 'weak-password') message = "Şifre çok zayıf.";
      _showMessage(message);
    } catch (e) {
      _showMessage("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orangeAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B263B),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                Text(
                  _isCompany ? 'Şirket / İş Veren Kaydı' : 'Sürücü Kaydı',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // --- ROL SEÇİMİ (TOGGLE) ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _roleOption("Şoför", Icons.local_shipping, !_isCompany),
                      ),
                      Expanded(
                        child: _roleOption("Şirket", Icons.business, _isCompany),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Eğer şirket seçiliyse en üstte şirket adı çıksın
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
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3722C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kaydı Tamamla', style: TextStyle(color: Colors.white, fontSize: 18)),
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

  // Rol seçimi için küçük buton tasarım fonksiyonu
  Widget _roleOption(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isCompany = (title == "Şirket")),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3722C) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
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
        prefixIcon: Icon(icon, color: const Color(0xFF1B263B)),
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