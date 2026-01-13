import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // --- BİLDİRİM GÖNDERME FONKSİYONU ---
  Future<void> _sendNotificationsToDrivers(String origin, String dest) async {
    try {
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var driverDoc in driversSnapshot.docs) {
        DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
        
        batch.set(notifyRef, {
          'receiverId': driverDoc.id,
          'title': 'Yeni Yük İlanı! 🚛',
          'message': '$origin -> $dest arası yeni bir yük ilanı yayınlandı. Hemen incele!',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'new_job',
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Bildirim gönderme hatası: $e");
    }
  }

  // --- KAYIT FONKSİYONU (GÜNCELLENDİ) ---
  Future<void> _ilaniKaydet() async {
    if (_originController.text.isEmpty || _destController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen zorunlu alanları doldurun!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Kullanıcı oturumu bulunamadı!");

      String companyDisplay = user.displayName ?? "Tirigo Üyesi";

      // KRİTİK NOKTA: userId parametresi eklendi
      await _firebaseService.ilanEkle(
        userId: user.uid, // İlan sahibinin gerçek ID'si
        origin: _originController.text.trim().toUpperCase(),
        destination: _destController.text.trim().toUpperCase(),
        loadType: _loadTypeController.text.trim(),
        weight: _weightController.text.trim(),
        truckType: _vehicleTypeController.text.trim(),
        price: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0,
        companyName: companyDisplay,
      );

      await _sendNotificationsToDrivers(
        _originController.text.trim().toUpperCase(),
        _destController.text.trim().toUpperCase(),
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
        title: const Text("Yeni İlan Yayınla", style: TextStyle(color: Colors.white, fontSize: 18)),
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
                controlsBuilder: (context, controls) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: controls.onStepContinue,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C)),
                          child: Text(_currentStep == 2 ? "YAYINLA" : "DEVAM ET", style: const TextStyle(color: Colors.white)),
                        ),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: controls.onStepCancel,
                            child: const Text("Geri", style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  );
                },
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
                        _buildField("Kalkış Şehri (Örn: İSTANBUL)", Icons.location_on, _originController),
                        const SizedBox(height: 10),
                        _buildField("Varış Şehri (Örn: ANKARA)", Icons.flag, _destController),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _currentStep >= 1,
                    title: const Text("Yük Bilgisi"),
                    content: Column(
                      children: [
                        _buildField("Yük Cinsi (Örn: Gıda, Demir)", Icons.inventory, _loadTypeController),
                        const SizedBox(height: 10),
                        _buildField("Ağırlık (Örn: 22 Ton)", Icons.fitness_center, _weightController),
                      ],
                    ),
                  ),
                  Step(
                    isActive: _currentStep >= 2,
                    title: const Text("Araç ve Fiyat"),
                    content: Column(
                      children: [
                        _buildField("Araç Tipi (Örn: Tenteli Tır)", Icons.local_shipping, _vehicleTypeController),
                        const SizedBox(height: 10),
                        _buildField("Fiyat (₺)", Icons.attach_money, _priceController, isNumeric: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String hint, IconData icon, TextEditingController controller, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("İlanınız başarıyla yayınlandı. Şoförler artık bu ilanı görebilir.", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog kapat
                Navigator.pop(context); // PostJob kapat
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Anladım", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}