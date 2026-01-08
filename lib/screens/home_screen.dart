import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import 'job_details_screen.dart';
import 'post_job_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  String? _userPhotoUrl;
  String _userRole = 'driver'; // Varsayılan rol

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userPhotoUrl = doc.data()?['photoUrl'];
            _userRole = doc.data()?['role'] ?? 'driver';
          });
        }
      } catch (e) {
        print("Kullanıcı verisi yükleme hatası: $e");
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
    // Şirketler için ilan ekleme butonu
    if (_userRole == 'company')
      IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostJobScreen()),
        ),
      ),
      
    // BİLDİRİM ZİLİ GÜNCELLEMESİ:
    IconButton(
      icon: const Icon(Icons.notifications_none, color: Colors.white),
      onPressed: () {
        // Zil ikonuna basıldığında bildirimler sayfasına gider
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
    ),

    Padding(
      padding: const EdgeInsets.only(right: 15),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFF3722C),
        backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
        child: _userPhotoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
      ),
    ),
  ],
),
      body: Column(
        children: [
          _buildTopSearchArea(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // GÜVENLİ SORGU: Index hatasını önlemek için orderBy'ı şimdilik kaldırdık
              stream: FirebaseFirestore.instance
    .collection('jobs')
    .where('status', isEqualTo: 'open') // Önce filtre
    .snapshots(),
              builder: (context, snapshot) {
                // HATA VARSA EKRANA YAZDIR (Kırmızı metin olarak)
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SelectableText(
                        "Firestore Hatası: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

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
                    
                    try {
                      JobModel job = JobModel.fromMap(jobData, doc.id);
                      return _buildJobCard(context, job);
                    } catch (e) {
                      return const SizedBox.shrink(); // Hatalı veriyi sessizce atla
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI YARDIMCI METODLARI ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("Şu an aktif ilan bulunmuyor.", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          const Text("İpucu: Veritabanında status='open' olan ilan var mı?", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

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
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailsScreen(
            jobData: job.toMap(),
            jobId: job.id,
          ),
        ),
      ),
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
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFF3722C), size: 20),
                            const SizedBox(width: 5),
                            Text(job.origin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Icon(Icons.arrow_right_alt, color: Colors.grey),
                            Text(job.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      Text('${job.price.toInt()} ₺', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  const Divider(height: 25),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text('${job.loadType} | ${job.weight}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
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
                  Text(job.companyName, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12)),
                  const Text('Detayları Gör >', style: TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}