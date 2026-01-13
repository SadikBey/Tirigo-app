import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// DEĞİŞİKLİK: Eski user_profile_screen.dart silindi, profile_screen.dart eklendi
import 'profile_screen.dart'; 

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String receiverId;

  const ChatDetailScreen({
    super.key, 
    required this.chatId, 
    required this.receiverName,
    required this.receiverId 
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': _auth.currentUser?.uid,
        'text': messageText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Mesaj gönderilemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Başlığa tıklayınca profile giden GestureDetector
        title: GestureDetector(
          onTap: () {
            // GÜNCELLEME: ProfileScreen çağırılıyor
            Navigator.push(context, MaterialPageRoute(
              builder: (c) => ProfileScreen(userId: widget.receiverId)
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const Text("Profili Görüntüle", style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz mesaj yok."));

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _auth.currentUser?.uid;
                    return _buildMessageBubble(data['text'] ?? "", isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFF3722C) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Mesajınızı yazın...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF1B263B),
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}