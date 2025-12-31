import 'package:flutter/material.dart';
import '../services/firebase_service.dart'; // Firebase servisini bağladık

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int _currentStep = 0;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false; // Yükleme durumunu kontrol eder

  // Form verilerini tutacak kontrolcüler
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _loadTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();

  @override
  void dispose() {
    // Bellek sızıntısını önlemek için kontrolcüleri temizliyoruz
    _originController.dispose();
    _destController.dispose();
    _loadTypeController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Yeni İlan Yayınla', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Kayıt sırasında ekranda yükleme simgesi gösterir
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)))
        : Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFFF3722C)),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () async {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  // Son adımda Firebase'e kayıt fonksiyonunu çağırıyoruz
                  await _ilaniKaydet(); 
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3722C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _currentStep == 2 ? 'İlanı Yayınla' : 'Devam Et', 
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Geri'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  title: const Text('Güzergâh Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      _buildField('Kalkış Noktası (Şehir/İlçe)', Icons.location_on_outlined, _originController),
                      const SizedBox(height: 10),
                      _buildField('Varış Noktası (Şehir/İlçe)', Icons.flag_outlined, _destController),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  title: const Text('Yük Detayları', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      _buildField('Yük Cinsi (Gıda, Tekstil vb.)', Icons.inventory_2_outlined, _loadTypeController),
                      const SizedBox(height: 10),
                      _buildField('Toplam Ağırlık (Ton)', Icons.fitness_center, _weightController),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 2,
                  title: const Text('Araç ve Fiyat', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      _buildField('İstenilen Araç Tipi', Icons.local_shipping_outlined, _vehicleTypeController),
                      const SizedBox(height: 10),
                      _buildField('Tahmini Fiyat (₺)', Icons.payments_outlined, _priceController),
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

  // --- KAYIT FONKSİYONU (Hatalardan Arındırılmış) ---
  Future<void> _ilaniKaydet() async {
    setState(() => _isLoading = true);

    try {
      await _firebaseService.ilanEkle(
        baslik: "${_loadTypeController.text} Taşımacılığı",
        aciklama: "${_weightController.text} ton ${_loadTypeController.text}, ${_vehicleTypeController.text} araç isteniyor.",
        nereden: _originController.text,
        nereye: _destController.text,
        fiyat: double.tryParse(_priceController.text) ?? 0.0,
        ilanSahibi: "Test Kullanıcısı", 
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text('İlanınız başarıyla oluşturuldu ve şoförlere iletildi.', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialogu kapat
              Navigator.pop(context); // Sayfayı kapat
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}