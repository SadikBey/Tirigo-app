import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'offers_list_screen.dart'; 

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobData, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _priceController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  
  bool _isSending = false;
  String _driverName = "Şoför";
  bool _isOwner = false;
  bool _isLoadingData = true; // Veri yüklenme kontrolü

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Verileri garantileyen yeni fonksiyon
  }

  // EKSİK VERİLERİ VERİTABANINDAN KURTARAN FONKSİYON
  Future<void> _loadInitialData() async {
    try {
      // Eğer userId (şirket ID) eksik gelmişse veritabanından çekelim
      if (widget.jobData['userId'] == null || widget.jobData['userId'].isEmpty) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .get();
            
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          widget.jobData['userId'] = data['userId']; // Eksik ID'yi tamamladık
        }
      }

      if (mounted) {
        setState(() {
          _isOwner = widget.jobData['userId'] == _currentUid;
          _priceController.text = (widget.jobData['price'] ?? "0").toString();
          _isLoadingData = false;
        });
        _loadDriverName();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
      debugPrint("Veri yükleme hatası: $e");
    }
  }

  Future<void> _loadDriverName() async {
    if (_isOwner) return; 
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      if (doc.exists && mounted) {
        setState(() {
          _driverName = doc.data()?['name'] ?? "Anonim Şoför";
        });
      }
    } catch (e) {
      debugPrint("Kullanıcı adı yüklenemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteCard(),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Yük Detayları"),
                  _buildDetailGrid(),
                  const SizedBox(height: 25),
                  _buildCompanyInfo(),
                  const SizedBox(height: 30),
                  _isOwner ? _buildCompanyAction() : _buildDriverAction(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF1B263B),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("İlan Detayı", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        background: Container(color: const Color(0xFF1B263B)),
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.radio_button_checked, color: Color(0xFFF3722C), size: 20),
              Container(width: 2, height: 40, color: Colors.grey[200]),
              const Icon(Icons.location_on, color: Color(0xFF1B263B), size: 24),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRouteItem("Kalkış Noktası", widget.jobData['origin']),
                const SizedBox(height: 25),
                _buildRouteItem("Varış Noktası", widget.jobData['destination']),
              ],
            ),
          ),
          Text(
            "${widget.jobData['price']} ₺",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFF3722C)),
          )
        ],
      ),
    );
  }

  Widget _buildRouteItem(String label, String? city) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        Text(city ?? "-", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 2.5,
      children: [
        _buildMiniCard(Icons.inventory_2_outlined, "Yük", widget.jobData['loadType']),
        _buildMiniCard(Icons.fitness_center, "Ağırlık", "${widget.jobData['weight']} kg"),
        _buildMiniCard(Icons.local_shipping_outlined, "Araç", widget.jobData['truckType']),
        _buildMiniCard(Icons.calendar_today_outlined, "Durum", widget.jobData['status'] == 'open' ? 'Aktif' : 'Kapalı'),
      ],
    );
  }

  Widget _buildMiniCard(IconData icon, String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF3722C)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(value ?? "-", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF1B263B), 
            child: Icon(Icons.business, color: Colors.white)
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("İlan Veren Firma", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(widget.jobData['companyName'] ?? "Tirigo Üyesi", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCompanyAction() {
    return Column(
      children: [
        const Text("Bu ilan size ait. Gelen teklifleri yönetebilirsiniz.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OffersListScreen(
                    jobId: widget.jobId,
                    jobTitle: "${widget.jobData['origin']} - ${widget.jobData['destination']}",
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            label: const Text("GELEN TEKLİFLERİ GÖR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B263B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFF3722C).withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text("Teklifinizi Belirleyin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 15),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFF3722C)),
            decoration: InputDecoration(
              suffixText: "₺",
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSending ? null : _handleSendOffer,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text("TEKLİFİ GÖNDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendOffer() async {
    final String? ownerId = widget.jobData['userId']; 
    
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata: İlan sahibinin ID'si hala bulunamadı!")),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      double offerPrice = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
      
      await _firebaseService.teklifVer(
        jobId: widget.jobId,
        offerPrice: offerPrice,
        driverName: _driverName,
        companyId: ownerId, 
        jobTitle: "${widget.jobData['origin']} -> ${widget.jobData['destination']}",
      );
      
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Teklif İletildi!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Şirket sahibi ile otomatik sohbet başlatıldı.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            TextButton(
              onPressed: () { 
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("TAMAM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B263B))),
    );
  }
}