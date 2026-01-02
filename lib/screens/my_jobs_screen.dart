import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'post_job_screen.dart';
import 'offers_list_screen.dart'; // Teklifler sayfasını içeri aktardık

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("İlanlarım ve İşlerim", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen())),
            icon: const Icon(Icons.add_box_rounded, color: Color(0xFFF3722C), size: 30),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.kullaniciIlanlariniGetir(_currentUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var jobDoc = snapshot.data!.docs[index];
              var jobData = jobDoc.data() as Map<String, dynamic>;
              
              return _buildJobCard(jobDoc.id, jobData);
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(String jobId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Text("${data['origin']} ➔ ${data['destination']}", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text("Yük: ${data['loadType']} | ${data['weight']}"),
                const SizedBox(height: 5),
                Text("Fiyat: ${data['price']} ₺", 
                  style: const TextStyle(color: Color(0xFFF3722C), fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: _buildStatusBadge(data['status'] ?? 'open'),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- TEKLİF SAYISINI GÖSTEREN VE SAYFAYA GİDEN BUTON ---
                StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.ilanaGelenTeklifleriGetir(jobId),
                  builder: (context, offerSnapshot) {
                    int offerCount = offerSnapshot.hasData ? offerSnapshot.data!.docs.length : 0;
                    return TextButton.icon(
                      onPressed: () {
                        // BURASI GÜNCELLENDİ: Teklifler Listesine Yönlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OffersListScreen(
                              jobId: jobId,
                              jobTitle: "${data['origin']} - ${data['destination']}",
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_offer_outlined, size: 18, color: Colors.blueGrey),
                      label: Text("$offerCount Teklif Geldi", 
                        style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => _confirmDelete(jobId),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isOpen = status.toLowerCase() == 'open' || status == 'Açık';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isOpen ? "Aktif" : "Kapalı",
        style: TextStyle(color: isOpen ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Henüz yayınlanmış bir ilanınız yok.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C)),
            child: const Text("Hemen İlan Yayınla", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _confirmDelete(String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () {
              _firebaseService.ilanSil(jobId);
              Navigator.pop(context);
            }, 
            child: const Text("Sil", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}