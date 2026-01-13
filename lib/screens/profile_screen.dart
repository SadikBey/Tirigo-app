import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Giriş ekranının doğru olduğundan emin ol

class ProfileScreen extends StatefulWidget {
  final String? userId; // Başka birinin profili için ID
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Kendi profilimiz mi?
  bool get _isOwnProfile =>
      widget.userId == null || widget.userId == FirebaseAuth.instance.currentUser?.uid;

  // --- 1. VERİ GÜNCELLEME (DİALOG) ---
  Future<void> _updateField(String fieldKey, String label, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$label Güncelle", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Yeni $label giriniz",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              String uid = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                fieldKey: controller.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 2. GÜVENLİ PUAN VERME (BOTTOM SHEET) ---
  void _showRatingSheet(BuildContext context, String targetId) {
    int selectedStars = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Hizmeti Değerlendir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.orange, size: 45),
                  onPressed: () => setModalState(() => selectedStars = index + 1),
                )),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (selectedStars == 0) return;
                    try {
                      DocumentReference ref = FirebaseFirestore.instance.collection('users').doc(targetId);
                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        DocumentSnapshot snap = await transaction.get(ref);
                        if (!snap.exists) return;
                        Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
                        double currentTotal = (data['totalRating'] ?? 0).toDouble();
                        int currentCount = (data['ratingCount'] ?? 0).toInt();
                        transaction.update(ref, {
                          'totalRating': currentTotal + selectedStars,
                          'ratingCount': currentCount + 1,
                        });
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Puan verildi!"), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      print("Hata: $e");
                    }
                  },
                  child: const Text("Değerlendirmeyi Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String targetId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
          if (!snapshot.data!.exists) return const Center(child: Text("Kullanıcı bulunamadı."));

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
          bool isCompany = userData['role'] == 'company';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(fullName, isCompany),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      _buildStatCard(targetId, userData),
                      const SizedBox(height: 20),
                      
                      if (!_isOwnProfile)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: OutlinedButton.icon(
                            onPressed: () => _showRatingSheet(context, targetId),
                            icon: const Icon(Icons.star_outline, color: Colors.orange),
                            label: const Text("Puan Ver & Değerlendir", style: TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25)),
                          ),
                        ),

                      if (isCompany)
                        _buildExpansionMenu(icon: Icons.business_rounded, title: "Kurumsal Bilgiler", children: [
                          _buildEditableRow("companyName", "Şirket Adı", userData['companyName'] ?? "-"),
                          _buildEditableRow("taxNumber", "Vergi No", userData['taxNumber'] ?? "-"),
                        ]),

                      _buildExpansionMenu(icon: Icons.person_outline_rounded, title: isCompany ? "Yetkili Bilgileri" : "Kişisel Bilgiler", children: [
                        _buildEditableRow("firstName", "Ad", userData['firstName'] ?? "-"),
                        _buildEditableRow("lastName", "Soyad", userData['lastName'] ?? "-"),
                        _buildEditableRow("city", "Şehir", userData['city'] ?? "-"),
                        _buildEditableRow("phone", "Telefon", userData['phone'] ?? "-"),
                      ]),

                      if (!isCompany)
                        _buildExpansionMenu(icon: Icons.local_shipping_outlined, title: "Araç Bilgileri", children: [
                          _buildEditableRow("truckType", "Araç Tipi", userData['truckType'] ?? "-"),
                          _buildEditableRow("plate", "Plaka", userData['plate'] ?? "-"),
                        ]),

                      if (_isOwnProfile) ...[
                        _buildExpansionMenu(icon: Icons.payments_outlined, title: "Ödeme Bilgilerim", children: [
                          _buildEditableRow("bankName", "Banka", userData['bankName'] ?? "-"),
                          _buildEditableRow("iban", "IBAN", userData['iban'] ?? "-"),
                        ]),
                        const SizedBox(height: 30),
                        _buildLogoutButton(),
                      ],
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- TASARIM BİLEŞENLERİ ---

  Widget _buildModernHeader(String name, bool isCompany) {
    const double maxH = 220.0;
    return SliverAppBar(
      expandedHeight: maxH, pinned: true, elevation: 0,
      backgroundColor: const Color(0xFF1B263B),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          var top = constraints.biggest.height;
          double progress = ((top - kToolbarHeight) / (maxH - kToolbarHeight)).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1B263B), Color(0xFF0D1B2A)])))),
              Positioned.fill(child: Opacity(opacity: 0.1 * progress, child: CustomPaint(painter: TechLinesPainter()))),
              Positioned(
                top: 45 * progress, left: 0, right: 0,
                child: Opacity(
                  opacity: progress,
                  child: Column(
                    children: [
                      CircleAvatar(radius: 45, backgroundColor: Colors.white, child: CircleAvatar(radius: 42, backgroundColor: const Color(0xFFF3722C), child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 8),
                      Text(isCompany ? "Şirket Sahibi" : "Sürücü", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Positioned(bottom: 15, left: 0, right: 0, child: Center(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String id, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').where('acceptedDriverId', isEqualTo: id).where('status', isEqualTo: 'completed').snapshots(),
      builder: (context, jobSnap) {
        int jobCount = jobSnap.hasData ? jobSnap.data!.docs.length : 0;
        double total = (data['totalRating'] ?? 0).toDouble();
        int count = (data['ratingCount'] ?? 0).toInt();
        double avg = count > 0 ? total / count : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Tamamlanan İş", jobCount.toString(), Icons.verified, Colors.green),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem("Puan", avg.toStringAsFixed(1), Icons.star, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12))]);
  }

  Widget _buildExpansionMenu({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(leading: Icon(icon, color: const Color(0xFF1B263B)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), children: children),
    );
  }

  Widget _buildEditableRow(String key, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
          if (_isOwnProfile) IconButton(icon: const Icon(Icons.edit_square, size: 18, color: Colors.blueGrey), onPressed: () => _updateField(key, label, value))
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      onTap: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false)),
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}

class TechLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.2); path.lineTo(size.width * 0.2, size.height * 0.4); path.lineTo(size.width * 0.4, size.height * 0.35);
    path.moveTo(size.width, size.height * 0.8); path.lineTo(size.width * 0.7, size.height * 0.6); path.lineTo(size.width * 0.8, size.height * 0.3);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}