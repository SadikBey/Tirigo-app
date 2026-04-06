import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'chat_service.dart';

/// Teklif (Offer) işlemlerinden sorumlu servis.
/// Single Responsibility: Sadece tekliflerle ilgili Firebase işlemleri burada.
class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();

  /// Belirli bir ilana gelen teklifleri stream olarak dinler
  Stream<QuerySnapshot> ilanaGelenTeklifleriGetir(String jobId) {
    return _firestore.collection('offers').where('jobId', isEqualTo: jobId).snapshots();
  }

  /// Şoför teklif verir, bildirim gönderir ve sohbet başlatır
  Future<void> teklifVer({
    required String jobId,
    required double offerPrice,
    required String driverName,
    required String companyId,
    required String jobTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Oturum açılmamış!");
    if (companyId.isEmpty) throw Exception("İlan sahibi bilgisi eksik. Lütfen sayfayı yenileyin.");

    final batch = _firestore.batch();

    // 1. Teklifi kaydet
    DocumentReference offerRef = _firestore.collection('offers').doc();
    batch.set(offerRef, {
      'jobId': jobId,
      'companyId': companyId,
      'driverId': user.uid,
      'driverName': driverName,
      'offeredPrice': offerPrice,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Firmaya bildirim gönder
    DocumentReference notificationRef = _firestore.collection('notifications').doc();
    batch.set(notificationRef, {
      'receiverId': companyId,
      'title': 'Yeni Teklif Geldi! 🚚',
      'message': '$driverName şoförü "$jobTitle" için $offerPrice ₺ teklif verdi.',
      'type': 'new_offer',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    try {
      // 3. Sohbet başlat ve ilk mesajı gönder
      String chatId = await _chatService.sohbetBaslat(companyId, "İlan Sahibi");

      DocumentReference msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(msgRef, {
        'senderId': user.uid,
        'text': '"$jobTitle" ilanınız için $offerPrice ₺ teklif verdim.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': '"$jobTitle" için $offerPrice ₺ teklif verildi.',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Teklifi onaylar, ilana şoförü atar ve bildirim gönderir
  Future<void> teklifiOnaylaVeBildirimGonder({
    required String jobId,
    required String offerId,
    required String driverId,
    required String jobTitle,
    required String driverName,
  }) async {
    final batch = _firestore.batch();

    // 1. Teklifi onayla
    batch.update(_firestore.collection('offers').doc(offerId), {'status': 'accepted'});

    // 2. İlanı güncelle
    batch.update(_firestore.collection('jobs').doc(jobId), {
      'status': 'closed',
      'acceptedDriverId': driverId,
      'acceptedDriverName': driverName,
    });

    // 3. Şoföre bildirim gönder
    DocumentReference notificationRef = _firestore.collection('notifications').doc();
    batch.set(notificationRef, {
      'receiverId': driverId,
      'title': 'Teklifiniz Onaylandı! 🎉',
      'message': '$jobTitle ilanı için teklifiniz kabul edildi. Hayırlı yolculuklar!',
      'type': 'offer_accepted',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  /// Teklif durumunu günceller (reddetme vb.)
  Future<void> teklifDurumuGuncelle(String offerId, String status) async {
    try {
      await _firestore.collection('offers').doc(offerId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Teklif güncellenirken hata: $e");
      rethrow;
    }
  }
}