import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatelessWidget {
  // HATA ÇÖZÜMÜ: userId parametresi eklendi. Eğer boş gelirse giriş yapan kişi kabul edilir.
  final String? userId; 

  const UserProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    // Eğer dışarıdan bir id gelmemişse, kendi ID'mi kullan
    final String targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Profil", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: targetUserId.isEmpty
          ? const Center(child: Text("Kullanıcı bulunamadı."))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Kullanıcı verisi bulunamadı."));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                
                String firstName = userData['firstName'] ?? "";
                String lastName = userData['lastName'] ?? "";
                String fullName = "$firstName $lastName".trim();
                if (fullName.isEmpty) fullName = "İsimsiz Kullanıcı";

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    children: [
                      _buildHeader(fullName, userData['email'] ?? ""),
                      const SizedBox(height: 30),
                      _buildStatCard(targetUserId),
                      const SizedBox(height: 25),
                      _buildInfoSection(userData),
                      const SizedBox(height: 40),
                      // Sadece kendi profilimdeysem çıkış butonunu göster
                      if (userId == null || userId == FirebaseAuth.instance.currentUser?.uid)
                        _buildLogoutButton(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: const Color(0xFF1B263B),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", 
            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B263B))),
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatCard(String id) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('acceptedDriverId', isEqualTo: id)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        int jobCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Tamamlanan İş", jobCount.toString(), Icons.verified, Colors.green),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem("Puan", "5.0", Icons.star, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Column(
      children: [
        _infoTile(Icons.phone_android, "Telefon", data['phone'] ?? "Eklenmemiş"),
        _infoTile(Icons.location_on_outlined, "Şehir", data['city'] ?? "Belirtilmemiş"),
        _infoTile(Icons.local_shipping_outlined, "Araç", data['truckType'] ?? "Belirtilmemiş"),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF3722C), size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => FirebaseAuth.instance.signOut(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
        ),
        child: const Text("Oturumu Kapat", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }
}