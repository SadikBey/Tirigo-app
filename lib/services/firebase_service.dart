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
  required String origin,
  required String destination,
  required String loadType,
  required String weight,
  required String truckType,
  required double price,
  required String companyName,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;

  await _firestore.collection('jobs').add({
    'userId': user.uid, // Şirketin ID'sini buraya kaydediyoruz
    'origin': origin,
    'destination': destination,
    'loadType': loadType,
    'weight': weight,
    'truckType': truckType,
    'price': price,
    'companyName': companyName,
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
  });
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

  // 5. Şoförün Teklif Vermesi (HEM BİLDİRİM HEM MESAJ KUTUSU AÇAR)
  // --- TEKLİF VERME: BİLDİRİM VE OTOMATİK SOHBET DAHİL ---
  Future<void> teklifVer({
    required String jobId,
    required double offerPrice,
    required String driverName,
    required String companyId, 
    required String jobTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Oturum açılmamış!");

    // KRİTİK KONTROL: Eğer companyId boş gelirse işlemi durdurur
    if (companyId.isEmpty || companyId == "") {
      print("HATA: companyId boş geldiği için işlem iptal edildi.");
      throw Exception("İlan sahibi bilgisi eksik. Lütfen sayfayı yenileyin.");
    }

    print("DEBUG: Teklif süreci başladı... Alıcı: $companyId");

    final batch = _firestore.batch();

    // 1. 'offers' koleksiyonuna teklifi ekle
    DocumentReference offerRef = _firestore.collection('offers').doc();
    batch.set(offerRef, {
      'jobId': jobId,
      'companyId': companyId,
      'driverId': user.uid,
      'driverName': driverName,
      'price': offerPrice,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. 'notifications' koleksiyonuna şirket için bildirim ekle
    DocumentReference notificationRef = _firestore.collection('notifications').doc();
    batch.set(notificationRef, {
      'receiverId': companyId,
      'title': 'Yeni Teklif Geldi! 🚚',
      'message': '$driverName şoförü "$jobTitle" ilanı için $offerPrice ₺ teklif verdi.',
      'type': 'new_offer',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    try {
      // 3. Sohbet odasını oluştur/hazırla
      String chatId = await sohbetBaslat(companyId, "İlan Sahibi");
      
      // 4. Sohbetin içine ilk mesajı otomatik at
      DocumentReference msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(msgRef, {
        'senderId': user.uid,
        'text': '"$jobTitle" ilanınız için $offerPrice ₺ teklif verdim. Detaylar için buradayım.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Sohbet listesindeki son mesaj önizlemesini güncelle
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': '"$jobTitle" için $offerPrice ₺ teklif verildi.',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Tüm işlemleri tek seferde Firebase'e gönder
      await batch.commit();
      print("BAŞARILI: Teklif, Bildirim ve Mesaj oluşturuldu.");
    } catch (e) {
      print("HATA: Batch işlemi sırasında bir sorun oluştu: $e");
      rethrow;
    }
  }

  Future<void> teklifDurumuGuncelle(String offerId, String newStatus) async {
    await _firestore.collection('offers').doc(offerId).update({
      'status': newStatus,
    });
  }

  // --- ONAYLAMA VE BİLDİRİM ---

  Future<void> teklifiOnaylaVeBildirimGonder({
    required String jobId,
    required String offerId,
    required String driverId,
    required String jobTitle,
    required String driverName,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('offers').doc(offerId), {'status': 'accepted'});
    batch.update(_firestore.collection('jobs').doc(jobId), {'status': 'closed'});

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
}