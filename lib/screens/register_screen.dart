import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Veritabanı için eklendi
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller'lar
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureText = true;

  // --- Kayıt ve Veritabanına Kaydetme Fonksiyonu ---
  Future<void> _register() async {
    // 1. Boşluk Kontrolü
    if (_firstNameController.text.isEmpty || 
        _lastNameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      _showMessage("Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Firebase Auth ile Kullanıcı Oluşturma
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Kullanıcı bilgilerini Firestore'a (veritabanına) kaydetme
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'driver', // Varsayılan olarak şoför rolü
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
      backgroundColor: const Color(0xFF1B263B), // Koyu Mavi
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const Text(
                  'Sürücü Kaydı',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Kayıt Formu (Beyaz Kart)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
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

                // Kayıt Butonu
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3722C), // Turuncu
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

  // Yardımcı input tasarım fonksiyonu
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