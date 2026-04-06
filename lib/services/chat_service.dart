import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Mesajlaşma (Chat) işlemlerinden sorumlu servis.
/// Single Responsibility: Sadece chat işlemleri burada.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sohbet başlatır veya mevcut sohbeti döndürür
  Future<String> sohbetBaslat(String otherUserId, String otherUserName) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return "";

    // İki kullanıcı ID'sini sıralayarak tutarlı chatId oluştur
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatId = ids.join("_");

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUserId, otherUserId],
      'otherUserName': otherUserName,
      'lastMessage': 'Sohbet başladı...',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  /// Mesaj gönderir
  Future<void> mesajGonder(String chatId, String text) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;

    final batch = _firestore.batch();

    DocumentReference msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Kullanıcının tüm sohbetlerini stream olarak dinler
  Stream<QuerySnapshot> sohbetleriDinle() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _auth.currentUser?.uid)
        .snapshots();
  }
}