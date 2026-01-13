import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'post_job_screen.dart';
import 'offers_list_screen.dart';
import 'job_details_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  String _userRole = 'driver'; 
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (_currentUid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'driver';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text(_userRole == 'company' ? "İlan Yönetimi" : "Aldığım İşler", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        bottom: _userRole == 'company' 
          ? TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF3722C),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: "Aktif İlanlarım", icon: Icon(Icons.outbox)),
                Tab(text: "Tamamlananlar", icon: Icon(Icons.history)),
              ],
            )
          : null,
        actions: [
          if (_userRole == 'company')
            IconButton(
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const PostJobScreen())
              ),
              icon: const Icon(Icons.add_box_rounded, color: Color(0xFFF3722C), size: 30),
            )
        ],
      ),
      body: _currentUid.isEmpty 
        ? const Center(child: Text("Lütfen giriş yapın."))
        : _userRole == 'company'
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildStreamList(FirebaseFirestore.instance.collection('jobs').where('userId', isEqualTo: _currentUid).where('status', whereIn: ['open', 'accepted']).snapshots(), true),
                  _buildStreamList(FirebaseFirestore.instance.collection('jobs').where('userId', isEqualTo: _currentUid).where('status', isEqualTo: 'completed').snapshots(), true),
                ],
              )
            : _buildStreamList(FirebaseFirestore.instance.collection('jobs').where('acceptedDriverId', isEqualTo: _currentUid).snapshots(), false),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // --- 1. KISIM: İLAN SAHİBİ PROFİL BARI ---
          _buildOwnerProfileBar(data['userId']),
          
          const Divider(height: 1, indent: 16, endIndent: 16),

          // --- 2. KISIM: İLAN İÇERİĞİ ---
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailsScreen(jobData: data, jobId: jobId))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${data['origin']?.toUpperCase()} ➔ ${data['destination']?.toUpperCase()}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Text("${data['loadType'] ?? 'Yük'} | ${data['weight'] ?? '0'} Ton", 
                          style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("${data['price'] ?? '0'} ₺", 
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 17)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(data['status'] ?? 'open'),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),

          // --- 3. KISIM: ALT AKSİYONLAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isOwner) ...[
                  _buildOfferButton(jobId, data),
                  IconButton(
                    onPressed: () => _confirmDelete(jobId),
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text("Bu İş Sizin Üzerinizde", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Icon(Icons.local_shipping, color: Colors.blue, size: 20),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- İLAN SAHİBİ ÇEKEN ÖZEL FONKSİYON ---
  Widget _buildOwnerProfileBar(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text("Hata: userId bulunamadı!", style: TextStyle(color: Colors.red, fontSize: 11)),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 40, child: Center(child: LinearProgressIndicator(minHeight: 1)));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var uData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Veritabanındaki farklı alan isimlerini destekler (name, userName, companyName)
          String name = uData['name'] ?? uData['userName'] ?? uData['companyName'] ?? "İsimsiz Kullanıcı";
          String? photoUrl = uData['photoUrl'];

          return InkWell(
            onTap: () {
               debugPrint("Profil Sayfasına Git: $ownerId");
               // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: ownerId)));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blueGrey[50],
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                    child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 14, color: Colors.blueGrey) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B263B))),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                ],
              ),
            ),
          );
        }

        // Kullanıcı ID'si var ama 'users' koleksiyonunda bu belge yoksa:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("⚠️ Kullanıcı Kaydı Eksik!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
              Text("ID: $ownerId", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfferButton(String jobId, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.ilanaGelenTeklifleriGetir(jobId),
      builder: (context, offerSnapshot) {
        int offerCount = offerSnapshot.hasData ? offerSnapshot.data!.docs.length : 0;
        return TextButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => OffersListScreen(jobId: jobId, jobTitle: "${data['origin']} - ${data['destination']}")
            ));
          },
          icon: Icon(Icons.local_offer, size: 16, color: offerCount > 0 ? Colors.green : Colors.blueGrey),
          label: Text("$offerCount Teklif", 
            style: TextStyle(color: offerCount > 0 ? Colors.green : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'open' ? Colors.green : (status == 'completed' ? Colors.grey : Colors.blue);
    String text = status == 'open' ? "YAYINDA" : (status == 'completed' ? "BİTTİ" : "YOLDA");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(bool isOwner) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(isOwner ? "Henüz bir ilanınız yok." : "Kabul ettiğiniz bir iş bulunmuyor.", style: const TextStyle(color: Colors.grey)),
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
          TextButton(onPressed: () { _firebaseService.ilanSil(jobId); Navigator.pop(context); }, child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}