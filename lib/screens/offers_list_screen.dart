import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 // Arama yapmak için
import '../services/firebase_service.dart';
import 'chat_detail_screen.dart';

class OffersListScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  OffersListScreen({super.key, required this.jobId, required this.jobTitle});

  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("$jobTitle - Teklifler", style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.ilanaGelenTeklifleriGetir(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bu ilana henüz teklif gelmedi."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var offerDoc = snapshot.data!.docs[index];
              var offerData = offerDoc.data() as Map<String, dynamic>;

              return _buildOfferCard(context, offerDoc.id, offerData);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, String offerId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF3722C),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['driverName'] ?? "İsimsiz Şoför", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Teklif: ${data['offeredPrice']} ₺", 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _statusChip(data['status']),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Mesaj At Butonu
              _actionButton(
                icon: Icons.chat_outlined,
                label: "Mesaj",
                color: Colors.blue,
                onTap: () async {
                  String chatId = await _firebaseService.sohbetBaslat(data['userId'], data['driverName']);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(chatId: chatId, otherUserName: data['driverName'])));
                },
              ),
              // Kabul Et Butonu
              _actionButton(
                icon: Icons.check_circle_outline,
                label: "Onayla",
                color: Colors.green,
                onTap: () => _firebaseService.teklifDurumuGuncelle(offerId, 'approved'),
              ),
              // Reddet Butonu
              _actionButton(
                icon: Icons.cancel_outlined,
                label: "Reddet",
                color: Colors.red,
                onTap: () => _firebaseService.teklifDurumuGuncelle(offerId, 'rejected'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    String text = "Bekliyor";
    if (status == 'approved') { color = Colors.green; text = "Onaylandı"; }
    if (status == 'rejected') { color = Colors.red; text = "Reddedildi"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}