import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Kullanıcı (User) işlemlerinden sorumlu servis.
/// Single Responsibility: Sadece kullanıcı verileri burada.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Kullanıcı verisini çeker
  Future<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  /// Kullanıcı alanını günceller
  Future<void> updateField(String fieldKey, String value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({fieldKey: value});
    } catch (e) {
      debugPrint("Alan güncellenemedi: $e");
      rethrow;
    }
  }

  /// Kullanıcıyı stream olarak dinler
  Stream<DocumentSnapshot> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}