import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Mesajlarım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sadece kullanıcının dahil olduğu sohbetleri getiriyoruz
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF3722C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildChatTile(chatData, snapshot.data!.docs[index].id);
            },
          );
        },
      ),
    );
  }

  // Sohbet Satırı Tasarımı
  Widget _buildChatTile(Map<String, dynamic> data, String chatId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF3722C),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          data['otherUserName'] ?? "Bilinmeyen Kullanıcı",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B263B)),
        ),
        subtitle: Text(
          data['lastMessage'] ?? "Mesaj bulunmuyor...",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            const SizedBox(height: 5),
            Text(
              "12:45", // Buraya timestamp gelecek
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatDetailScreen(
        chatId: chatId,
        otherUserName: data['otherUserName'] ?? "Kullanıcı",
      ),
    ),
  );
},
      ),
    );
  }

  // Mesaj Yoksa Gösterilecek Ekran
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "Henüz mesajınız yok",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Text("İlanlar üzerinden teklif vererek\niletişime geçebilirsiniz.", textAlign: TextAlign.center),
        ],
      ),
    );
  }
}