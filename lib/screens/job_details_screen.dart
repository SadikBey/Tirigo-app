import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'chat_detail_screen.dart';

class JobDetailsScreen extends StatelessWidget { // Sınıf adını 's' takısı ile güncelledik
  final Map<String, dynamic> jobData;
  final String jobId;

  JobDetailsScreen({super.key, required this.jobData, required this.jobId});

  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("İlan Detayı", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- GÜZERGAH VE FİYAT KARTI ---
            _buildHeaderCard(),
            
            // --- YÜK VE ARAÇ BİLGİLERİ ---
            _buildDetailSection(),

            // --- ŞİRKET BİLGİSİ ---
            _buildCompanyCard(),
            
            const SizedBox(height: 100), // Butonlar için boşluk
          ],
        ),
      ),
      // --- ALT AKSİYON BUTONLARI ---
      bottomSheet: _buildActionButtons(context),
    );
  }

  // --- TEKLİF VERME PENCERESİ (MODAL) ---
  void _showBidSheet(BuildContext context) {
    final TextEditingController _bidController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Teklifinizi Girin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Önerilen Fiyat: ${jobData['price']} ₺", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFFF3722C)),
                hintText: "Örn: 4500",
                suffixText: "₺",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_bidController.text.isNotEmpty) {
                    double offeredPrice = double.parse(_bidController.text);
                    await _firebaseService.teklifVer(
                      jobId: jobId,
                      origin: jobData['origin'],
                      destination: jobData['destination'],
                      offeredPrice: offeredPrice,
                      driverName: "Şoför", // Burası dinamik yapılabilir
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Teklifiniz başarıyla iletildi!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B263B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Teklifi Gönder", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B263B),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLocationColumn("Kalkış", jobData['origin']),
              const Icon(Icons.arrow_forward, color: Color(0xFFF3722C), size: 30),
              _buildLocationColumn("Varış", jobData['destination']),
            ],
          ),
          const SizedBox(height: 20),
          Text("${jobData['price']} ₺", 
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Önerilen Fiyat", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLocationColumn(String label, String city) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(city, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Yük Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.inventory_2_outlined, "Yük Tipi", jobData['loadType']),
          _buildInfoRow(Icons.monitor_weight_outlined, "Ağırlık", jobData['weight']),
          _buildInfoRow(Icons.local_shipping_outlined, "Araç Tipi", jobData['truckType']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B263B), size: 24),
          const SizedBox(width: 15),
          Text("$title: ", style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCompanyCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFF3722C), child: Icon(Icons.business, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jobData['companyName'] ?? "Şirket Bilgisi Yok", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Tirigo Onaylı İş Ortağı", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              Text(jobData['companyRate']?.toString() ?? "4.8", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () async {
                String chatId = await _firebaseService.sohbetBaslat(jobData['userId'], jobData['companyName']);
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(chatId: chatId, otherUserName: jobData['companyName'])));
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1B263B)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Soru Sor", style: TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _showBidSheet(context), // BURASI GÜNCELLENDİ
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3722C),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Teklif Ver", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}