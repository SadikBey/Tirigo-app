import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controller'lar
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false; // Düzenleme modu açık mı?
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // --- Firestore'dan Verileri Çek ---
  Future<void> _getUserData() async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar("Veriler yüklenirken hata oluştu.");
      setState(() => _isLoading = false);
    }
  }

  // --- Verileri Güncelle ---
  Future<void> _updateUserData() async {
    setState(() => _isLoading = true);
    try {
      String uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      _showSnackBar("Bilgileriniz başarıyla güncellendi!", isError: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Güncelleme sırasında hata oluştu.");
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kişisel Bilgiler', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateUserData();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  // Profil Resmi Alanı (Temsili)
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFF0F2F5),
                      child: Icon(Icons.person, size: 60, color: Color(0xFF1B263B)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bilgi Formu
                  _buildTextField("Adınız", _firstNameController, Icons.person_outline),
                  _buildTextField("Soyadınız", _lastNameController, Icons.person_outline),
                  _buildTextField("Telefon Numaranız", _phoneController, Icons.phone_android_outlined, isPhone: true),
                  _buildTextField("E-posta (Değiştirilemez)", _emailController, Icons.email_outlined, enabled: false),

                  if (_isEditing)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Şu an düzenleme modundasınız.",
                        style: TextStyle(color: Color(0xFFF3722C), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPhone = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        enabled: enabled && _isEditing, // Sadece düzenleme modu açıksa aktifleşir
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B263B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: !(_isEditing && enabled),
          fillColor: (_isEditing && enabled) ? Colors.transparent : Colors.grey[100],
        ),
      ),
    );
  }
}