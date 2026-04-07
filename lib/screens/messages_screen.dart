import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/constants/constants.dart'; // Renk sabitleri için ekledik
import 'chat_detail_screen.dart';
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
      // Arka planı genel uygulama rengine uydurduk
      backgroundColor: AppColors.backgroundLight, 
      
      // AppBar'ı buradan kaldırdık çünkü MainScreen'deki ortak AppBar'ı kullanıyoruz.
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            // Not: Hata almamak için orderBy kısmını şimdilik eklemedik.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

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
        String? photoUrl;
        
        if (userSnap.hasData && userSnap.data!.exists) {
          var userData = userSnap.data!.data() as Map<String, dynamic>;
          String fName = userData['firstName'] ?? "";
          String lName = userData['lastName'] ?? "";
          name = "$fName $lName".trim();
          photoUrl = userData['photoUrl'];
          
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
                Navigator.push(context, MaterialPageRoute(
                  builder: (c) => ProfileScreen(userId: otherUserId)
                ));
              },
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1), 
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) 
                    ? const Icon(Icons.person, color: AppColors.primary) 
                    : null,
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            subtitle: Text(
              data['lastMessage'] ?? "Mesaj bulunmuyor...", 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: Text(
              _formatDateTime(data['updatedAt'] as Timestamp?), 
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)
            ),
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

  // Mesaj yoksa görünecek şık ekran
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Henüz mesajınız yok",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}