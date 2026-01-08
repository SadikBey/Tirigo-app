import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class OffersListScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const OffersListScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  State<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        title: Text(widget.jobTitle, 
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .where('jobId', isEqualTo: widget.jobId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var offerDoc = snapshot.data!.docs[index];
              var offerData = offerDoc.data() as Map<String, dynamic>;
              return _buildOfferCard(offerDoc.id, offerData);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(String offerId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'pending';
    String price = data['price']?.toString() ?? data['offerPrice']?.toString() ?? "0";
    String driverId = data['driverId'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- İSİMSİZ SORUNUNU ÇÖZEN KISIM ---
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(driverId).get(),
                  builder: (context, userSnap) {
                    String fullName = "Şoför";
                    if (userSnap.hasData && userSnap.data!.exists) {
                      var uData = userSnap.data!.data() as Map<String, dynamic>;
                      fullName = "${uData['firstName'] ?? ''} ${uData['lastName'] ?? ''}".trim();
                      if (fullName.isEmpty) fullName = "İsimsiz Şoför";
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const Text("Teklif Verildi", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    );
                  },
                ),
                Text("$price ₺", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Divider(height: 30),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _firebaseService.teklifDurumuGuncelle(offerId, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("REDDET", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApproval(offerId, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              _buildStatusIndicator(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    bool isAccepted = (status == 'accepted' || status == 'approved');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isAccepted ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isAccepted ? "BU TEKLİF ONAYLANDI" : "REDDEDİLDİ",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isAccepted ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Future<void> _handleApproval(String offerId, Map<String, dynamic> data) async {
  try {
    String driverId = data['driverId'] ?? "";
    
    // 1. ADIM: İlanı şoföre ata (Firebase dökümanını günceller)
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'acceptedDriverId': driverId,
      'status': 'closed',
    });

    // 2. ADIM: Bildirimi Gönder (Burası bildirim gelmesini sağlar)
    // driverName verisi null ise yedek olarak 'Şoför' yazıyoruz
    await _firebaseService.teklifiOnaylaVeBildirimGonder(
      jobId: widget.jobId,
      offerId: offerId,
      driverId: driverId,
      jobTitle: widget.jobTitle,
      driverName: data['driverName'] ?? "Şoför",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Onaylandı ve Bildirim Gönderildi!")),
      );
    }
  } catch (e) {
    print("Bildirim Gönderim Hatası: $e");
  }
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Henüz bir teklif almadınız.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}