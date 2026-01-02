import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Koleksiyon Referansları
  CollectionReference get _jobsRef => _firestore.collection('jobs');
  CollectionReference get _chatsRef => _firestore.collection('chats');
  CollectionReference get _offersRef => _firestore.collection('offers');

  // --- İLAN EKLEME ---
  Future<void> ilanEkle({
    required String origin,
    required String destination,
    required double price,
    required String loadType,
    required String weight,
    required String truckType,
    required String companyName,
    required String status,
  }) async {
    final user = _auth.currentUser;
    await _jobsRef.add({
      'userId': user?.uid,
      'origin': origin,
      'destination': destination,
      'price': price,
      'loadType': loadType,
      'weight': weight,
      'truckType': truckType,
      'companyName': companyName,
      'companyRate': 4.5,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- İLANLARI LİSTELEME ---
  Stream<QuerySnapshot> ilanlariGetir() {
    return _jobsRef
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> kullaniciIlanlariniGetir(String uid) {
    return _jobsRef.where('userId', isEqualTo: uid).snapshots();
  }

  // --- MESAJLAŞMA (Sohbet Başlatma) ---
  Future<String> sohbetBaslat(String otherUserId, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "";

    // Benzersiz Chat ID oluşturma (İki ID'yi sıralayıp birleştiriyoruz)
    List<String> ids = [currentUser.uid, otherUserId];
    ids.sort();
    String chatId = ids.join("_");

    DocumentReference chatDoc = _chatsRef.doc(chatId);
    DocumentSnapshot chatSnapshot = await chatDoc.get();

    if (!chatSnapshot.exists) {
      await chatDoc.set({
        'participants': ids,
        'lastMessage': "Sohbet başladı...",
        'lastMessageTime': FieldValue.serverTimestamp(),
        'otherUserName': otherUserName, // Listelemede kolaylık sağlar
      });
    }
    return chatId;
  }

  // --- ŞOFÖR TEKLİF VERME ---
  Future<void> teklifVer({
    required String jobId,
    required String origin,
    required String destination,
    required double offeredPrice,
    required String driverName,
  }) async {
    await _offersRef.add({
      'jobId': jobId,
      'userId': _auth.currentUser?.uid,
      'origin': origin,
      'destination': destination,
      'offeredPrice': offeredPrice,
      'driverName': driverName,
      'status': 'pending', // Beklemede, approved, rejected
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- TEKLİF YÖNETİMİ (Şirket İçin) ---
  // Gelen teklifi onaylama veya reddetme
  Future<void> teklifDurumuGuncelle(String offerId, String newStatus) async {
    await _offersRef.doc(offerId).update({
      'status': newStatus,
    });
  }

  // Belirli bir ilana gelen tüm teklifleri izleme
  Stream<QuerySnapshot> ilanaGelenTeklifleriGetir(String jobId) {
    return _offersRef
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- İLAN SİLME ---
  Future<void> ilanSil(String docId) async {
    try {
      await _jobsRef.doc(docId).delete();
    } catch (e) {
      print("Silme hatası: $e");
    }
  }

  Future<void> sifremiUnuttum(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email);
  } catch (e) {
    throw Exception("Şifre sıfırlama e-postası gönderilemedi: $e");
  }
}
}