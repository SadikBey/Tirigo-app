import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B263B),
          title: const Text('İlan Yönetimi', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF3722C),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'İlanlarım'),
              Tab(text: 'Yoldakiler'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyJobsTab(firebaseService, 'Açık'),   // Yayınlanan ilanlar
            _buildMyJobsTab(firebaseService, 'Yolda'),  // Onaylanmış, yoldaki işler
            _buildMyJobsTab(firebaseService, 'Kapalı'), // Bitmiş işler
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobsTab(FirebaseService service, String status) {
    return StreamBuilder<QuerySnapshot>(
      // Firebase'den bu firmanın ilanlarını çekiyoruz
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('companyName', isEqualTo: "Tirigo Lojistik")
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("Bu kategoride kayıt bulunamadı."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var jobData = docs[index].data() as Map<String, dynamic>;
            String jobId = docs[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${jobData['origin']} ➔ ${jobData['destination']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        _statusBadge(status),
                      ],
                    ),
                    const Divider(height: 20),
                    
                    // --- TEKLİF SAYISINI DİNAMİK GÖSTERME ---
                    StreamBuilder<QuerySnapshot>(
                      stream: service.ilanaGelenTeklifleriGetir(jobId),
                      builder: (context, offerSnapshot) {
                        int count = offerSnapshot.data?.docs.length ?? 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("$count Teklif Alındı", style: const TextStyle(color: Colors.blueGrey)),
                            if (status == 'Açık')
                              ElevatedButton(
                                onPressed: () => _showOffersModal(context, jobId, service),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C)),
                                child: const Text("Teklifleri İncele", style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Gelen Teklifleri Gösteren Modal
  void _showOffersModal(BuildContext context, String jobId, FirebaseService service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: service.ilanaGelenTeklifleriGetir(jobId),
          builder: (context, snapshot) {
            final offers = snapshot.data?.docs ?? [];
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text("Gelen Teklifler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      var offer = offers[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(offer['driverName']),
                        subtitle: Text("Fiyat: ${offer['offeredPrice']} ₺"),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Onaylama mantığı buraya gelecek
                            Navigator.pop(context);
                          },
                          child: const Text("Kabul Et"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'Açık' ? Colors.green : (status == 'Yolda' ? Colors.blue : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}