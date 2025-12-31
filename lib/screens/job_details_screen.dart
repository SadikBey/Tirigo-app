import 'package:flutter/material.dart';
import '../models/job_model.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _offerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka planı koyu lacivert yapıyoruz ki yazılar patlasın
      backgroundColor: const Color(0xFF1B263B), 
      appBar: AppBar(
        title: const Text("Yük Detayları", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst Kısım: Rota Görseli (Harita Yerine)
            Container(
              padding: const EdgeInsets.all(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _routeInfo("YÜKLEME", widget.job.origin),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFFF3722C), size: 30),
                  _routeInfo("TESLİMAT", widget.job.destination),
                ],
              ),
            ),

            const Divider(color: Colors.white24, indent: 20, endIndent: 20),

            // Orta Kısım: Detay Kartları
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow("Yük Tipi", widget.job.loadType),
                  _buildDetailRow("Ağırlık", widget.job.weight),
                  _buildDetailRow("Araç", widget.job.truckType),
                  _buildDetailRow("Firma", widget.job.companyName),
                  
                  const SizedBox(height: 40),

                  // Fiyat Bilgisi (Büyük ve Parlak)
                  const Text(
                    "TAHMİNİ KAZANÇ",
                    style: TextStyle(color: Colors.white60, fontSize: 14, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${widget.job.price.toInt()} ₺",
                    style: const TextStyle(
                      color: Color(0xFF00FF88), // Parlak Neon Yeşil
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Alt Buton Alanı
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showOfferSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3722C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Teklif Ver", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 15),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(Icons.star_border, color: Colors.black54),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Şehir Bilgisi Helper
  Widget _routeInfo(String label, String city) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 5),
        Text(city, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Detay Satırı Helper
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Teklif Penceresi
  void _showOfferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Teklifinizi Girin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _offerController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "₺0.00",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B263B),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("TEKLİFİ GÖNDER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}