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
  String _userRole = 'driver';

  // Arama ve Filtreleme Kontrolcüleri
  final TextEditingController _originSearchController = TextEditingController();
  final TextEditingController _destSearchController = TextEditingController();
  String _originFilter = "";
  String _destFilter = "";
  
  // Filtreleme Seçenekleri
  String _selectedLoadType = "Hepsi";
  String _selectedVehicleType = "Hepsi";
  final List<String> _loadTypes = ["Hepsi", "Gıda", "Demir", "Tekstil", "İnşaat", "Kimyasal", "Mobilya"];
  final List<String> _vehicleTypes = ["Hepsi", "Tenteli Tır", "Kamyon", "Onteker", "Panelvan", "Kırkayak"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenForNewNotifications();
  }

  // --- BİLDİRİM VE VERİ DİNLEYİCİLERİ ---

  void _listenForNewNotifications() {
    final String currentUid = _auth.currentUser?.uid ?? "";
    FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _showInAppNotification(data['title'] ?? 'Yeni Bildirim', data['message'] ?? '');
        }
      }
    });
  }

  void _showInAppNotification(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1B263B),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'GÖR',
          textColor: const Color(0xFFF3722C),
          onPressed: _showNotificationsPopup,
        ),
      ),
    );
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
        debugPrint("Hata: $e");
      }
    }
  }

  // --- FİLTRELEME BOTTOM SHEET ---

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Filtrele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() { _selectedLoadType = "Hepsi"; _selectedVehicleType = "Hepsi"; });
                          setState(() { _selectedLoadType = "Hepsi"; _selectedVehicleType = "Hepsi"; });
                        },
                        child: const Text("Sıfırla", style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text("Yük Cinsi", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _loadTypes.map((type) {
                      bool isSelected = _selectedLoadType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: const Color(0xFFF3722C),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (val) {
                          setModalState(() => _selectedLoadType = type);
                          setState(() => _selectedLoadType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Araç Tipi", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _vehicleTypes.map((type) {
                      bool isSelected = _selectedVehicleType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B263B),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (val) {
                          setModalState(() => _selectedVehicleType = type);
                          setState(() => _selectedVehicleType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3722C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("SONUÇLARI GÖSTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsPopup() async {
    final String currentUid = _auth.currentUser?.uid ?? "";
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .get();

    if (notifications.docs.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = _auth.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        centerTitle: false,
        title: const Text("Tirigo", style: TextStyle(color: Color(0xFFF3722C), fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          if (_userRole == 'company')
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen())),
            ),
          _buildNotificationIcon(currentUid),
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          _buildTopSearchArea(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'open')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                // FİLTRELEME MANTIĞI
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String origin = (data['origin'] ?? "").toString().toLowerCase();
                  String dest = (data['destination'] ?? "").toString().toLowerCase();
                  String loadType = (data['loadType'] ?? "");
                  String vehicle = (data['truckType'] ?? "");

                  bool matchesSearch = origin.contains(_originFilter.toLowerCase()) && 
                                       dest.contains(_destFilter.toLowerCase());
                  bool matchesLoad = (_selectedLoadType == "Hepsi") || (loadType == _selectedLoadType);
                  bool matchesVehicle = (_selectedVehicleType == "Hepsi") || (vehicle == _selectedVehicleType);

                  return matchesSearch && matchesLoad && matchesVehicle;
                }).toList();

                if (filteredDocs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    JobModel job = JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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

  // --- UI BİLEŞENLERİ ---

  Widget _buildTopSearchArea() {
    bool hasActiveFilter = _selectedLoadType != "Hepsi" || _selectedVehicleType != "Hepsi";

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B263B),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildSearchField(_originSearchController, 'Nereden?', (val) => setState(() => _originFilter = val)),
                  const Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                  _buildSearchField(_destSearchController, 'Nereye?', (val) => setState(() => _destFilter = val)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasActiveFilter ? const Color(0xFFF3722C) : const Color(0xFF3E4A5E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hint, Function(String) onChanged) {
    return Expanded(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications')
          .where('receiverId', isEqualTo: currentUid)
          .where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        bool hasNotif = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28), onPressed: _showNotificationsPopup),
            if (hasNotif) Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF3722C), shape: BoxShape.circle))),
          ],
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 5),
      child: CircleAvatar(
        radius: 17,
        backgroundColor: Colors.white24,
        backgroundImage: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty ? NetworkImage(_userPhotoUrl!) : null,
        child: (_userPhotoUrl == null || _userPhotoUrl!.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailsScreen(jobData: job.toMap(), jobId: job.id))),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // 1. ÜST KISIM: Rota ve Fiyat
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFF3722C), size: 18),
                        const SizedBox(width: 4),
                        Flexible(child: Text(job.origin.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
                        ),
                        Flexible(child: Text(job.destination.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      ],
                    ),
                  ),
                  Text('${job.price.toInt()} ₺', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
            ),
            
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 2. ORTA KISIM: Yük Bilgileri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text('${job.loadType} | ${job.weight} Ton', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),

            const Divider(height: 1),

            // 3. ALT KISIM: Dinamik Profil Barı
            _buildMiniProfileBar(job),
          ],
        ),
      ),
    );
  }

  // Yeni Eklenen Dinamik Profil Barı Fonksiyonu
  Widget _buildMiniProfileBar(JobModel job) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(job.userId).get(),
      builder: (context, snapshot) {
        String name = job.companyName; // Default olarak modeldeki companyName
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          var uData = snapshot.data!.data() as Map<String, dynamic>;
          name = uData['name'] ?? uData['userName'] ?? job.companyName;
          photoUrl = uData['photoUrl'];
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: Colors.blueGrey[50],
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 14, color: Colors.blueGrey) : null,
              ),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Text('Detayları Gör >', style: TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Sonuç bulunamadı.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}