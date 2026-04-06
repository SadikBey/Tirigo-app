import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';
import '../services/firebase_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  int _currentStep = 0;

  // Controllers
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // Seçimler
  String _selectedLoadType = '';
  String _selectedVehicleType = '';

  final List<String> _loadTypes = ['Gıda', 'Demir', 'Tekstil', 'İnşaat', 'Kimyasal', 'Mobilya', 'Elektronik', 'Diğer'];
  final List<String> _vehicleTypes = ['Tenteli Tır', 'Kamyon', 'Onteker', 'Panelvan', 'Kırkayak', 'Frigorifik'];

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _weightCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _step0Valid => _originCtrl.text.isNotEmpty && _destCtrl.text.isNotEmpty;
  bool get _step1Valid => _selectedLoadType.isNotEmpty && _weightCtrl.text.isNotEmpty;
  bool get _step2Valid => _selectedVehicleType.isNotEmpty && _priceCtrl.text.isNotEmpty;

  Future<void> _ilaniKaydet() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Oturum bulunamadı!");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String companyDisplay = "Tirigo Üyesi";
      if (userDoc.exists) {
        final d = userDoc.data() as Map<String, dynamic>;
        final fullName = "${d['firstName'] ?? ''} ${d['lastName'] ?? ''}".trim();
        if (fullName.isNotEmpty) companyDisplay = fullName;
        else if ((d['companyName'] ?? '').toString().isNotEmpty) companyDisplay = d['companyName'];
      }

      await _firebaseService.ilanEkle(
        userId: user.uid,
        origin: _originCtrl.text.trim().toUpperCase(),
        destination: _destCtrl.text.trim().toUpperCase(),
        loadType: _selectedLoadType,
        weight: _weightCtrl.text.trim(),
        truckType: _selectedVehicleType,
        price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
        companyName: companyDisplay,
      );

      // Şoförlere bildirim gönder
      final driversSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').get();
      final batch = FirebaseFirestore.instance.batch();
      for (var d in driversSnap.docs) {
        batch.set(FirebaseFirestore.instance.collection('notifications').doc(), {
          'receiverId': d.id,
          'title': 'Yeni Yük İlanı! 🚛',
          'message': '${_originCtrl.text.trim().toUpperCase()} → ${_destCtrl.text.trim().toUpperCase()} arası yeni ilan!',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'new_job',
        });
      }
      await batch.commit();

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
        title: const Text("Yeni İlan Yayınla", style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : Column(
              children: [
                // Adım göstergesi
                _buildStepIndicator(),

                // İçerik
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),

                // Alt butonlar
                _buildBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Güzergâh', 'Yük', 'Araç & Fiyat'];
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : isActive ? AppColors.secondary : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text("${i + 1}", style: TextStyle(
                                color: isActive ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(steps[i], style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2, margin: const EdgeInsets.only(bottom: 18),
                      color: isDone ? AppColors.success : Colors.white24,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      default: return const SizedBox();
    }
  }

  // ── ADIM 0: GÜZERGÂH ──
  Widget _buildStep0() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Güzergâh Bilgisi", style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text("Yükün nereden nereye gideceğini girin.", style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        const SizedBox(height: 24),

        _buildLabel("Kalkış Şehri"),
        const SizedBox(height: 8),
        _buildTextField(_originCtrl, "Örn: İSTANBUL", Icons.radio_button_checked, isUpper: true),
        const SizedBox(height: 20),

        _buildLabel("Varış Şehri"),
        const SizedBox(height: 8),
        _buildTextField(_destCtrl, "Örn: ANKARA", Icons.location_on, isUpper: true),
      ],
    );
  }

  // ── ADIM 1: YÜK BİLGİSİ ──
  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Yük Bilgisi", style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text("Taşınacak yükün cinsini ve ağırlığını seçin.", style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        const SizedBox(height: 24),

        _buildLabel("Yük Cinsi"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _loadTypes.map((type) {
            final selected = _selectedLoadType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedLoadType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.secondary : Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: selected ? [BoxShadow(color: AppColors.secondaryWithOpacity(0.3), blurRadius: 8)] : [],
                ),
                child: Text(type, style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _buildLabel("Ağırlık"),
        const SizedBox(height: 8),
        _buildTextField(_weightCtrl, "Örn: 22", Icons.fitness_center_outlined, isNumeric: true),
      ],
    );
  }

  // ── ADIM 2: ARAÇ & FİYAT ──
  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Araç & Fiyat", style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text("İstediğiniz araç tipini ve ücretini belirleyin.", style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        const SizedBox(height: 24),

        _buildLabel("Araç Tipi"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _vehicleTypes.map((type) {
            final selected = _selectedVehicleType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedVehicleType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(type, style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _buildLabel("Fiyat (₺)"),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondaryWithOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 28),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text("₺", style: TextStyle(fontSize: 22, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Özet
        if (_originCtrl.text.isNotEmpty && _destCtrl.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryWithOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("İlan Özeti", style: AppTextStyles.labelBold),
                const SizedBox(height: 8),
                _buildSummaryRow("Güzergâh", "${_originCtrl.text} → ${_destCtrl.text}"),
                if (_selectedLoadType.isNotEmpty) _buildSummaryRow("Yük", "$_selectedLoadType | ${_weightCtrl.text}"),
                if (_selectedVehicleType.isNotEmpty) _buildSummaryRow("Araç", _selectedVehicleType),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Geri", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  if (!_step0Valid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen kalkış ve varış şehirlerini girin.")),
                    );
                    return;
                  }
                  setState(() => _currentStep++);
                } else if (_currentStep == 1) {
                  if (!_step1Valid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen yük cinsi ve ağırlık girin.")),
                    );
                    return;
                  }
                  setState(() => _currentStep++);
                } else {
                  if (!_step2Valid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen araç tipi ve fiyat girin.")),
                    );
                    return;
                  }
                  _ilaniKaydet();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? AppColors.success : AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                isLastStep ? "İlanı Yayınla 🚛" : "Devam Et",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.labelBold);
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {bool isNumeric = false, bool isUpper = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      textCapitalization: isUpper ? TextCapitalization.characters : TextCapitalization.none,
      onChanged: isUpper ? (v) {
        final upper = v.toUpperCase();
        if (upper != v) {
          controller.value = TextEditingValue(
            text: upper,
            selection: TextSelection.collapsed(offset: upper.length),
          );
        }
        setState(() {});
      } : (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 70),
            const SizedBox(height: 12),
            const Text("İlan Yayınlandı!", style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            const Text("Şoförler artık ilanınızı görebilir.",
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Harika!", style: AppTextStyles.buttonPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}