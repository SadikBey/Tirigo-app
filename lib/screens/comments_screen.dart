import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Puanlar ve Yorumlar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Şoförün kendi ID'sine gelen yorumları çekiyoruz
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('comments')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildCommentCard(data);
            },
          );
        },
      ),
    );
  }

  // --- Yorum Kartı Tasarımı ---
  Widget _buildCommentCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Yorum Yapanın Adı (Anonim Değil)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF3722C).withOpacity(0.1),
                    child: Text(data['senderName'][0].toUpperCase(), 
                         style: const TextStyle(color: Color(0xFFF3722C), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    data['senderName'] ?? "Müşteri",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              // Puan Yıldızları
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: index < (data['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Yorum Metni
          Text(
            data['comment'] ?? "",
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 10),
          // Tarih
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatDate(data['date']),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
          Icon(Icons.comment_bank_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 15),
          const Text("Henüz hiç yorum almadınız.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "";
    DateTime dt = (date as Timestamp).toDate();
    return "${dt.day}.${dt.month}.${dt.year}";
  }
}