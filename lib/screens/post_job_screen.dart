import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int _currentStep = 0;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  // Kontrolcüler
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _loadTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _loadTypeController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  // --- KAYIT FONKSİYONU (HATASIZ HALİ) ---
  Future<void> _ilaniKaydet() async {
    if (_originController.text.isEmpty || _destController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen şehir bilgilerini doldurun!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // FirebaseService'deki yeni isimlendirmelere göre gönderiyoruz
      await _firebaseService.ilanEkle(
        origin: _originController.text.trim().toUpperCase(),
        destination: _destController.text.trim().toUpperCase(),
        loadType: _loadTypeController.text.trim(),
        weight: _weightController.text.trim(),
        truckType: _vehicleTypeController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        companyName: "Tirigo Lojistik", 
        status: "Açık",
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni İlan Yayınla", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)))
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFFF3722C)),
              ),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _ilaniKaydet();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep -= 1);
                },
                steps: [
                  Step(
                    isActive: _currentStep >= 0,
                    title: const Text("Güzergâh"),
                    content: Column(
                      children: [
                        _buildField("Kalkış Şehri", Icons.location_on, _originController),
                        const SizedBox(height: 10),
                        _buildField("Varış Şehri", Icons.flag, _destController),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _currentStep >= 1,
                    title: const Text("Yük Bilgisi"),
                    content: Column(
                      children: [
                        _buildField("Yük Cinsi", Icons.inventory, _loadTypeController),
                        const SizedBox(height: 10),
                        _buildField("Ağırlık", Icons.fitness_center, _weightController),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _currentStep >= 2,
                    title: const Text("Araç ve Fiyat"),
                    content: Column(
                      children: [
                        _buildField("Araç Tipi", Icons.local_shipping, _vehicleTypeController),
                        const SizedBox(height: 10),
                        _buildField("Fiyat (₺)", Icons.attach_money, _priceController),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String hint, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1B263B)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Text("İlanınız başarıyla yayınlandı."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Sayfa
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }
}