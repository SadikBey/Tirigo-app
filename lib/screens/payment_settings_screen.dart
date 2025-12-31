import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  // --- Firestore'dan Mevcut Ödeme Bilgilerini Getir ---
  Future<void> _loadPaymentData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        // Eğer 'paymentDetails' diye bir map varsa içini doldur
        if (data.containsKey('paymentDetails')) {
          var payment = data['paymentDetails'];
          _bankNameController.text = payment['bankName'] ?? '';
          _accountHolderController.text = payment['accountHolder'] ?? '';
          _ibanController.text = payment['iban'] ?? '';
        }
      }
    } catch (e) {
      _showSnackBar("Bilgiler yüklenirken hata oluştu.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Bilgileri Firestore'a Kaydet/Güncelle ---
  Future<void> _savePaymentData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'paymentDetails': {
          'bankName': _bankNameController.text.trim(),
          'accountHolder': _accountHolderController.text.trim(),
          'iban': _ibanController.text.trim().replaceAll(' ', ''),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
      _showSnackBar("Ödeme bilgileriniz kaydedildi.", isError: false);
    } catch (e) {
      _showSnackBar("Kaydedilirken bir hata oluştu.");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Ödeme Bilgilerim", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kazançlarınızın yatırılacağı banka hesabını tanımlayın.",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 25),
                    
                    _buildInputLabel("Banka Adı"),
                    _buildTextField(_bankNameController, "Örn: Ziraat Bankası", Icons.account_balance_rounded),
                    
                    _buildInputLabel("Hesap Sahibi (Ad Soyad)"),
                    _buildTextField(_accountHolderController, "Örn: Ahmet Yılmaz", Icons.person_rounded),
                    
                    _buildInputLabel("IBAN Numarası"),
                    _buildTextField(
                      _ibanController, 
                      "TR00 0000 0000...", 
                      Icons.credit_card_rounded,
                      isIban: true
                    ),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePaymentData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3722C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Bilgileri Güncelle", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B263B))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isIban = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: (value) => value!.isEmpty ? "Bu alan boş bırakılamaz" : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1B263B)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black12)),
        ),
      ),
    );
  }
}