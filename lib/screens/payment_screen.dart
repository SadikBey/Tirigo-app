import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _bankNameCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = true;
  String? _selectedBank;

  final List<Map<String, dynamic>> _banks = [
    {'name': 'Ziraat Bankası', 'color': const Color(0xFF1B5E20)},
    {'name': 'İş Bankası', 'color': const Color(0xFF1565C0)},
    {'name': 'Garanti BBVA', 'color': const Color(0xFF2E7D32)},
    {'name': 'Akbank', 'color': const Color(0xFFB71C1C)},
    {'name': 'Yapı Kredi', 'color': const Color(0xFF4527A0)},
    {'name': 'Halkbank', 'color': const Color(0xFF01579B)},
    {'name': 'Vakıfbank', 'color': const Color(0xFF004D40)},
    {'name': 'Diğer', 'color': AppColors.primary},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      _bankNameCtrl.text = data['bankName'] ?? '';
      _ibanCtrl.text = data['iban'] ?? '';
      _selectedBank = data['bankName'];
      setState(() => _isFetching = false);
    } else {
      setState(() => _isFetching = false);
    }
  }

  String _formatIban(String value) {
    final clean = value.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  Future<void> _save() async {
    if (_selectedBank == null || _ibanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun."), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'bankName': _selectedBank,
        'iban': _ibanCtrl.text.trim().replaceAll(' ', ''),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ödeme bilgileri kaydedildi! ✅"), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Ödeme Bilgileri", style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Güvenlik bandı
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: AppColors.success, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Bilgileriniz 256-bit şifreleme ile korunmaktadır.",
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Banka Seçimi
                  const Text("Banka Seçin", style: AppTextStyles.labelBold),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: _banks.map((bank) {
                      final isSelected = _selectedBank == bank['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBank = bank['name'] as String),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? (bank['color'] as Color) : AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? (bank['color'] as Color) : Colors.grey.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: (bank['color'] as Color).withValues(alpha: 0.3), blurRadius: 8)] : [],
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                bank['name'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // IBAN
                  const Text("IBAN Numarası", style: AppTextStyles.labelBold),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ibanCtrl,
                    maxLength: 32,
                    onChanged: (v) {
                      final formatted = _formatIban(v);
                      if (formatted != v) {
                        _ibanCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "TR00 0000 0000 0000 0000 0000 00",
                      prefixIcon: const Icon(Icons.credit_card_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.backgroundCard,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.textWhite)
                          : const Text("Kaydet", style: AppTextStyles.buttonPrimary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}