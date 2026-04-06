import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// İlan (Job) işlemlerinden sorumlu servis.
/// Single Responsibility: Sadece ilanlarla ilgili Firebase işlemleri burada.
class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Yeni ilan ekler
  Future<void> ilanEkle({
    required String userId,
    required String origin,
    required String destination,
    required String loadType,
    required String weight,
    required String truckType,
    required double price,
    required String companyName,
  }) async {
    try {
      await _firestore.collection('jobs').add({
        'userId': userId,
        'origin': origin,
        'destination': destination,
        'loadType': loadType,
        'weight': weight,
        'truckType': truckType,
        'price': price,
        'companyName': companyName,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedDriverId': null,
        'acceptedDriverName': null,
      });
    } catch (e) {
      debugPrint("İlan ekleme hatası: $e");
      rethrow;
    }
  }

  /// İlanı siler, ilgili teklifleri de temizler
  Future<void> ilanSil(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      final offers = await _firestore.collection('offers').where('jobId', isEqualTo: jobId).get();
      for (var doc in offers.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("İlan silinirken hata: $e");
      rethrow;
    }
  }

  /// İşi tamamlandı olarak işaretler (şoför tarafından)
  Future<void> isiTamamla(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("İş tamamlanırken hata: $e");
      rethrow;
    }
  }

  /// Kullanıcının ilanlarını stream olarak dinler
  Stream<QuerySnapshot> kullaniciIlanlariniGetir(String uid) {
    return _firestore.collection('jobs').where('userId', isEqualTo: uid).snapshots();
  }
}