import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- KULLANICI İŞLEMLERİ ---
  String? get currentUserId => _auth.currentUser?.uid;

  Future<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  // --- İLAN (JOB) İŞLEMLERİ ---

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
        // Başlangıçta bu alanlar boş durmalı
        'acceptedDriverId': null,
        'acceptedDriverName': null,
      });
    } catch (e) {
      print("İlan ekleme hatası: $e");
      rethrow;
    }
  }

  // --- YENİ: İŞİ TAMAMLA (Şoför Tarafından) ---
  Future<void> isiTamamla(String jobId) async {
    try {
      // İşin durumunu 'completed' (tamamlandı) yapar ve bitiş zamanını ekler
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("İş tamamlanırken hata: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> kullaniciIlanlariniGetir(String uid) {
    return _firestore
        .collection('jobs')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> ilanSil(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      var offers = await _firestore.collection('offers').where('jobId', isEqualTo: jobId).get();
      for (var doc in offers.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("İlan silinirken hata: $e");
    }
  }

  // --- TEKLİF (OFFER) İŞLEMLERİ ---

  Stream<QuerySnapshot> ilanaGelenTeklifleriGetir(String jobId) {
    return _firestore
        .collection('offers')
        .where('jobId', isEqualTo: jobId)
        .snapshots();
  }

  Future<void> teklifVer({
    required String jobId,
    required double offerPrice,
    required String driverName,
    required String companyId,
    required String jobTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Oturum açılmamış!");

    if (companyId.isEmpty) {
      throw Exception("İlan sahibi bilgisi eksik. Lütfen sayfayı yenileyin.");
    }

    final batch = _firestore.batch();

    // 1. 'offers' koleksiyonuna teklifi ekle
    DocumentReference offerRef = _firestore.collection('offers').doc();
    batch.set(offerRef, {
      'jobId': jobId,
      'companyId': companyId,
      'driverId': user.uid,
      'driverName': driverName,
      'offeredPrice': offerPrice, // JobDetailsScreen ile uyumlu isim
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. 'notifications' bildirim ekle
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
      String chatId = await sohbetBaslat(companyId, "İlan Sahibi");
      
      DocumentReference msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(msgRef, {
        'senderId': user.uid,
        'text': '"$jobTitle" ilanınız için $offerPrice ₺ teklif verdim.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': '"$jobTitle" için $offerPrice ₺ teklif verildi.',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // --- GÜNCELLENEN ONAYLAMA FONKSİYONU ---
  // Teklif onaylandığında şoförün ID'sini işin (Job) içine yazar.
  Future<void> teklifiOnaylaVeBildirimGonder({
    required String jobId,
    required String offerId,
    required String driverId,
    required String jobTitle,
    required String driverName,
  }) async {
    final batch = _firestore.batch();

    // 1. Teklifi 'accepted' yap
    batch.update(_firestore.collection('offers').doc(offerId), {'status': 'accepted'});

    // 2. İlanı 'closed' yap (veya 'on_the_way') VE şoför ID'sini ekle
    // BURASI JobDetailsScreen'deki isJobOnMe kontrolünün çalışmasını sağlar
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

  // --- MESAJLAŞMA (CHAT) İŞLEMLERİ ---

  Future<String> sohbetBaslat(String otherUserId, String otherUserName) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return "";

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

  Future<void> mesajGonder(String chatId, String text) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;

    final batch = _firestore.batch();
    DocumentReference msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    
    batch.set(msgRef, {
      'senderId': uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> sohbetleriDinle() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _auth.currentUser?.uid)
        .snapshots();
  }

  // --- TEKLİF DURUMUNU GÜNCELLE (REDDETME İÇİN) ---
  // Arayüzden gelen 'rejected' komutunu Firestore'a iletir.
  Future<void> teklifDurumuGuncelle(String offerId, String status) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(), // Zaman damgası eklemek rapor için iyidir
          });
    } catch (e) {
      print("Teklif güncellenirken hata oluştu: $e");
      rethrow;
    }
  }
}