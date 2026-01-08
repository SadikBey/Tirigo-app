import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyOrdersScreen extends StatelessWidget {
  const CompanyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yayınladığım İlanlar"),
        backgroundColor: const Color(0xFF1B263B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('userId', isEqualTo: user?.uid) // Sadece kendi ilanları
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final jobs = snapshot.data!.docs;
          if (jobs.isEmpty) return const Center(child: Text("Henüz bir ilan yayınlamadınız."));

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              var job = jobs[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("${job['origin']} -> ${job['destination']}"),
                  subtitle: Text("Durum: ${job['status']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Teklifleri göreceği alt sayfaya gidecek
                    _showOffersBottomSheet(context, job.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Gelen Teklifleri Gösteren Alt Pencere
  void _showOffersBottomSheet(BuildContext context, String jobId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text("Gelen Teklifler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('offers')
                      .where('jobId', isEqualTo: jobId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final offers = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        var offer = offers[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(offer['driverName']),
                          subtitle: Text("${offer['price']} ₺"),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Onaylama fonksiyonu buraya gelecek
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Teklif Kabul Edildi! Mesajlaşma Başlıyor...")),
                              );
                            },
                            child: const Text("Onayla"),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}