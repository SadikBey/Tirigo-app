import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Giriş ekranına yönlendirme için eklendi
import 'personal_info_screen.dart';
import 'payment_settings_screen.dart';
import 'comments_screen.dart';
import 'vehicle_document_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = "Yükleniyor...";
  String _userRole = "Yükleniyor...";
  double _rating = 0.0;
  bool _isLoading = true;

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
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _fullName = "${data['firstName']} ${data['lastName']}";
            // Rolü Türkçeleştirelim
            String role = data['role'] ?? 'driver';
            _userRole = role == 'company' ? "Şirket Sahibi" : "Sürücü";
            _rating = data.containsKey('rating') ? (data['rating'] as num).toDouble() : 4.8;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ASIL ÇIKIŞ YAPMA FONKSİYONU ---
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Tüm sayfaları temizleyerek Login ekranına gönderir
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Çıkış hatası: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // --- ÜST PROFİL KARTI ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1B263B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFFF3722C),
                  child: Text(
                    _isLoading ? "?" : _fullName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),
                Text(_fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 5),
                    Text(_rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_userRole, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- MENÜ LİSTESİ ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              children: [
                _buildMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: "Kişisel Bilgiler",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen())),
                ),
                _buildMenuTile(
                  icon: Icons.star_border_rounded,
                  title: "Puanlarım ve Yorumlar",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommentsScreen())),
                ),
                _buildMenuTile(
                  icon: Icons.payments_outlined,
                  title: "Ödeme Bilgilerim",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSettingsScreen())),
                ),
                _buildMenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: "Araç ve Belge Bilgileri",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleDocumentScreen())),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                _buildMenuTile(
                  icon: Icons.logout_rounded,
                  title: "Çıkış Yap",
                  color: Colors.redAccent,
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap, Color color = const Color(0xFF1B263B)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Hesabınızdan çıkış yapmak üzeresiniz. Emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              _handleLogout(); // Çıkış işlemini başlat
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}