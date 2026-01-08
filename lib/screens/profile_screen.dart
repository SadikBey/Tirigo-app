import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _fullName = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _fullName = "${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditSheet(String fieldName, String label, String currentValue) {
    TextEditingController _controller = TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            Text("$label Düzenle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({fieldName: _controller.text});
                    _loadUserInfo();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güncellendi"), backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3722C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Şirket olup olmadığını kontrol et
    bool isCompany = _userData['role'] == 'company';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildTopHeader(isCompany),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  children: [
                    // --- ŞİRKETLERE ÖZEL: KURUMSAL BİLGİLER ---
                    if (isCompany)
                      _buildExpansionMenu(
                        icon: Icons.business_rounded,
                        title: "Kurumsal Bilgiler",
                        children: [
                          _buildEditableRow("companyName", "Şirket Adı", _userData['companyName'] ?? "Eklenmemiş"),
                          _buildEditableRow("taxNumber", "Vergi Numarası", _userData['taxNumber'] ?? "Eklenmemiş"),
                          _buildEditableRow("taxOffice", "Vergi Dairesi", _userData['taxOffice'] ?? "Eklenmemiş"),
                        ],
                      ),

                    // KİŞİSEL / YETKİLİ BİLGİLERİ
                    _buildExpansionMenu(
                      icon: Icons.person_outline_rounded,
                      title: isCompany ? "Yetkili Bilgileri" : "Kişisel Bilgiler",
                      children: [
                        _buildEditableRow("firstName", "Ad", _userData['firstName'] ?? ""),
                        _buildEditableRow("lastName", "Soyad", _userData['lastName'] ?? ""),
                        _buildEditableRow("city", "Şehir", _userData['city'] ?? "Belirtilmemiş"),
                        _buildEditableRow("phone", "Telefon", _userData['phone'] ?? "Belirtilmemiş"),
                        _buildEditableRow("email", "E-posta", _userData['email'] ?? "-"),
                      ],
                    ),

                    // --- SÜRÜCÜLERE ÖZEL: ARAÇ BİLGİLERİ ---
                    if (!isCompany)
                      _buildExpansionMenu(
                        icon: Icons.local_shipping_outlined,
                        title: "Araç ve Belge Bilgileri",
                        children: [
                          _buildEditableRow("truckType", "Araç Tipi", _userData['truckType'] ?? "Belirtilmemiş"),
                          _buildEditableRow("plate", "Plaka", _userData['plate'] ?? "Belirtilmemiş"),
                          _buildInfoRow("SRC Belgesi", "Onaylı ✅"),
                        ],
                      ),

                    // ORTAK: ÖDEME BİLGİLERİ
                    _buildExpansionMenu(
                      icon: Icons.payments_outlined,
                      title: "Ödeme Bilgilerim",
                      children: [
                        _buildEditableRow("bankName", "Banka", _userData['bankName'] ?? "Ziraat Bankası"),
                        _buildEditableRow("iban", "IBAN", _userData['iban'] ?? "TR00 0000 0000 0000 0000 0000 00"),
                      ],
                    ),

                    const SizedBox(height: 30),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  // --- MODERN HEADER ---
  Widget _buildTopHeader(bool isCompany) {
    return Container(
      width: double.infinity,
      height: 280,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B263B), Color(0xFF0D1B2A)],
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
          ),
          Positioned.fill(
            child: Opacity(opacity: 0.15, child: CustomPaint(painter: TechLinesPainter())),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFF3722C).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFFF3722C),
                        child: Text(
                          _fullName.isNotEmpty ? _fullName[0].toUpperCase() : "?",
                          style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(_fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isCompany ? Icons.business : Icons.local_shipping, color: Colors.white70, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          isCompany ? "Şirket Sahibi" : "Sürücü",
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionMenu({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF1B263B)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 15),
          children: children,
        ),
      ),
    );
  }

  Widget _buildEditableRow(String fieldName, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          IconButton(
            icon: const Icon(Icons.edit_square, size: 18, color: Colors.blueGrey),
            onPressed: () => _showEditSheet(fieldName, label, value),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      onTap: () => FirebaseAuth.instance.signOut().then((value) => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false)),
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}

class TechLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.35);
    path.moveTo(size.width, size.height * 0.8);
    path.lineTo(size.width * 0.7, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.3);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 2, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 2, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}