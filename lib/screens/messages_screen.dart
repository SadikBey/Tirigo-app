import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
// DEĞİŞİKLİK: Eski user_profile_screen.dart yerine profile_screen.dart import edildi
import 'profile_screen.dart'; 

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Mesajlarım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz mesajınız yok"));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var chatData = doc.data() as Map<String, dynamic>;
              List participants = chatData['participants'] ?? [];
              String otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => "");
              
              return _buildChatTile(chatData, doc.id, otherUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> data, String chatId, String otherUserId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnap) {
        String name = "Yükleniyor...";
        
        if (userSnap.hasData && userSnap.data!.exists) {
          var userData = userSnap.data!.data() as Map<String, dynamic>;
          String fName = userData['firstName'] ?? "";
          String lName = userData['lastName'] ?? "";
          name = "$fName $lName".trim();
          
          if (name.isEmpty) {
            name = userData['email']?.split('@')[0] ?? "Kullanıcı";
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: ListTile(
            leading: GestureDetector(
              onTap: () {
                // GÜNCELLEME: UserProfileScreen yerine ProfileScreen çağırılıyor
                Navigator.push(context, MaterialPageRoute(
                  builder: (c) => ProfileScreen(userId: otherUserId)
                ));
              },
              child: const CircleAvatar(
                backgroundColor: Color(0xFFF3722C), 
                child: Icon(Icons.person, color: Colors.white)
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(data['lastMessage'] ?? "Mesaj bulunmuyor...", maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(_formatDateTime(data['updatedAt'] as Timestamp?), style: const TextStyle(fontSize: 10)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: chatId, 
                  receiverName: name, 
                  receiverId: otherUserId
                )
              ));
            },
          ),
        );
      }
    );
  }
}