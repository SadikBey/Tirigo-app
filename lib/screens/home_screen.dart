import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import 'job_details_screen.dart';
import 'post_job_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfilePhoto();
  }

  // Profil fotoğrafını Firestore'dan çekme
  Future<void> _loadUserProfilePhoto() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userPhotoUrl = doc.data()?['photoUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: Image.asset('assets/images/tirigo_yazi_logo.png', height: 35),
        actions: [
          // İlan Ekleme Butonu
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen())),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          // Profil Avatarı (Dinamik)
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF3722C),
              backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
              child: _userPhotoUrl == null 
                ? const Icon(Icons.person, size: 20, color: Colors.white) 
                : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopSearchArea(),
          
          // --- FIREBASE STREAMBUILDER ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Firestore'daki 'jobs' koleksiyonunu dinle
              // Sadece 'status'u open (açık) olanları getir
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'open')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var jobData = doc.data() as Map<String, dynamic>;
                    
                    // Firestore verisini JobModel'e dönüştür
                    JobModel job = JobModel.fromMap(jobData, doc.id);

                    return _buildJobCard(context, job);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("Şu an aktif ilan bulunmuyor.", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Arama ve Filtreleme Alanı (Görsel Tasarımı Korudum)
  Widget _buildTopSearchArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFF1B263B),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Nereden - Nereye yük bakıyorsun?',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFF3722C)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('En Yakın'),
                _filterChip('Yüksek Fiyat'),
                _filterChip('Acil Yükler'),
                _filterChip('Tenteli'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  // İlan Kartı Tasarımı
  Widget _buildJobCard(BuildContext context, JobModel job) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailsScreen(job: job))),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFF3722C), size: 20),
                          const SizedBox(width: 5),
                          Text(job.origin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Icon(Icons.arrow_right_alt, color: Colors.grey),
                          Text(job.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text('${job.price.toInt()} ₺', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const Divider(height: 25),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text('${job.loadType} | ${job.weight}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(job.truckType, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.companyName, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const Text('Detayları Gör >', style: TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}