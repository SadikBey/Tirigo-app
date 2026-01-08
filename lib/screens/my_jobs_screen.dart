import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'post_job_screen.dart';
import 'offers_list_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("İşlerim ve İlanlarım", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF3722C),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Yayınladıklarım", icon: Icon(Icons.outbox)),
            Tab(text: "Aldığım İşler", icon: Icon(Icons.assignment_turned_in)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const PostJobScreen())
            ),
            icon: const Icon(Icons.add_box_rounded, color: Color(0xFFF3722C), size: 30),
          )
        ],
      ),
      body: currentUid.isEmpty 
        ? const Center(child: Text("Lütfen giriş yapın."))
        : TabBarView(
            controller: _tabController,
            children: [
              // 1. SEKME: İlan Sahibi Olarak (Kendi yayınladığın ilanlar)
              // Firebase'deki 'userId' alanına göre çekiyoruz
              _buildStreamList(
                FirebaseFirestore.instance
                    .collection('jobs')
                    .where('userId', isEqualTo: currentUid)
                    .snapshots(), 
                true
              ),
              
              // 2. SEKME: Şoför Olarak (Kabul ettiğin/aldığın işler)
              // BURASI ÖNEMLİ: İlan onaylandığında 'acceptedDriverId' alanı oluşmalı
              _buildStreamList(
                FirebaseFirestore.instance
                    .collection('jobs')
                    .where('acceptedDriverId', isEqualTo: currentUid)
                    .snapshots(), 
                false
              ),
            ],
          ),
    );
  }

  Widget _buildStreamList(Stream<QuerySnapshot> stream, bool isOwner) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isOwner);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var jobDoc = snapshot.data!.docs[index];
            var jobData = jobDoc.data() as Map<String, dynamic>;
            return _buildJobCard(jobDoc.id, jobData, isOwner);
          },
        );
      },
    );
  }

  Widget _buildJobCard(String jobId, Map<String, dynamic> data, bool isOwner) {
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
            title: Text("${data['origin'] ?? 'Bilinmiyor'} ➔ ${data['destination'] ?? 'Bilinmiyor'}", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${data['loadType'] ?? 'Yük'} | ${data['weight'] ?? '0'} kg"),
                  ],
                ),
                const SizedBox(height: 8),
                Text("${data['price'] ?? '0'} ₺", 
                  style: const TextStyle(color: Color(0xFFF3722C), fontWeight: FontWeight.bold, fontSize: 16)),
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
                if (isOwner) ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.ilanaGelenTeklifleriGetir(jobId),
                    builder: (context, offerSnapshot) {
                      int offerCount = offerSnapshot.hasData ? offerSnapshot.data!.docs.length : 0;
                      return TextButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => OffersListScreen(
                              jobId: jobId,
                              jobTitle: "${data['origin']} - ${data['destination']}",
                            ),
                          ));
                        },
                        icon: Icon(Icons.local_offer_outlined, size: 18, color: offerCount > 0 ? Colors.green : Colors.blueGrey),
                        label: Text("$offerCount Teklif", style: TextStyle(color: offerCount > 0 ? Colors.green : Colors.blueGrey, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(jobId),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text("Bu İşi Aldınız", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isOpen = status.toLowerCase() == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isOpen ? "Aktif" : "Onaylandı",
        style: TextStyle(color: isOpen ? Colors.green : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(bool isOwner) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(isOwner ? "Henüz yayınlanmış bir ilanınız yok." : "Kabul edilen bir işiniz bulunmuyor.", 
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinize emin misiniz?"),
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