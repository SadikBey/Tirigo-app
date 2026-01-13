import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Container(
      // Pop-up'ın üst köşelerini yuvarlıyoruz
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Üst tutma çizgisi
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Bildirimler", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B263B))),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('receiverId', isEqualTo: currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildNotificationCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();
    String formattedTime = date != null ? DateFormat('HH:mm').format(date) : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF3722C).withOpacity(0.1),
          child: const Icon(Icons.notifications_active, color: Color(0xFFF3722C)),
        ),
        title: Text(data['title'] ?? "Bildirim", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['message'] ?? ""),
        trailing: Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Henüz bir bildiriminiz yok", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}