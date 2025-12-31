import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleDocumentScreen extends StatefulWidget {
  const VehicleDocumentScreen({super.key});

  @override
  State<VehicleDocumentScreen> createState() => _VehicleDocumentScreenState();
}

class _VehicleDocumentScreenState extends State<VehicleDocumentScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Controller'lar
  final _plateController = TextEditingController();
  String? _selectedVehicleType;
  String? _selectedCaseType;

  bool _isLoading = true;

  // Örnek Liste Verileri
  final List<String> _vehicleTypes = ['Çekici', 'Kırkayak', 'Onteker', 'Panelvan', 'Kamyonet'];
  final List<String> _caseTypes = ['Tenteli', 'Açık Kasa', 'Frigofirik', 'Damperli', 'Konteyner'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('vehicleInfo')) {
          var vInfo = data['vehicleInfo'];
          setState(() {
            _plateController.text = vInfo['plate'] ?? '';
            _selectedVehicleType = vInfo['vehicleType'];
            _selectedCaseType = vInfo['caseType'];
          });
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Araç ve Belge Bilgileri", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Araç Teknik Detayları"),
                  _buildVehicleForm(),
                  
                  const SizedBox(height: 30),
                  
                  _sectionTitle("Yasal Belgeler & Onay Durumu"),
                  _buildDocumentStatusCard("Sürücü Belgesi (Ehliyet)", true),
                  _buildDocumentStatusCard("SRC 3/4 Belgesi", true),
                  _buildDocumentStatusCard("Psikoteknik Raporu", false),
                  _buildDocumentStatusCard("Araç Ruhsatı", true),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Verileri güncelleme fonksiyonu
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3722C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Bilgileri Güncelle", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B263B))),
    );
  }

  Widget _buildVehicleForm() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // Araç Tipi Seçimi
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            decoration: const InputDecoration(labelText: "Araç Tipi", prefixIcon: Icon(Icons.local_shipping)),
            items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _selectedVehicleType = val),
          ),
          const SizedBox(height: 15),
          // Kasa Tipi Seçimi
          DropdownButtonFormField<String>(
            value: _selectedCaseType,
            decoration: const InputDecoration(labelText: "Kasa Tipi", prefixIcon: Icon(Icons.inventory_2)),
            items: _caseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _selectedCaseType = val),
          ),
          const SizedBox(height: 15),
          // Plaka
          TextField(
            controller: _plateController,
            decoration: const InputDecoration(labelText: "Plaka", prefixIcon: Icon(Icons.badge)),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusCard(String title, bool isUploaded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUploaded ? Colors.green.shade100 : Colors.orange.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isUploaded ? Icons.check_circle : Icons.warning_amber_rounded, 
                   color: isUploaded ? Colors.green : Colors.orange),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          TextButton(
            onPressed: () {
              // Fotoğraf yükleme sayfasına veya galeriye yönlendir
            },
            child: Text(isUploaded ? "Görüntüle" : "Yükle", 
                       style: TextStyle(color: isUploaded ? Colors.blue : Colors.red)),
          )
        ],
      ),
    );
  }
}