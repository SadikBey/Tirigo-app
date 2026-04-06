import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_service.dart';
import 'offer_service.dart';
import 'chat_service.dart';
import 'user_service.dart';

export 'job_service.dart';
export 'offer_service.dart';
export 'chat_service.dart';
export 'user_service.dart';

/// FirebaseService — Facade Pattern
/// 
/// Geriye dönük uyumluluk için tüm servisleri tek çatı altında toplar.
/// Ekranlar bu sınıfı kullanmaya devam edebilir, ya da
/// doğrudan JobService, OfferService, ChatService, UserService kullanabilir.
/// 
/// DRY: İş mantığı tekrarlanmaz, ilgili servise delege edilir.
class FirebaseService {
  final JobService _jobService = JobService();
  final OfferService _offerService = OfferService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  String? get currentUserId => _userService.currentUserId;

  // --- İLAN İŞLEMLERİ ---
  Future<void> ilanEkle({
    required String userId,
    required String origin,
    required String destination,
    required String loadType,
    required String weight,
    required String truckType,
    required double price,
    required String companyName,
  }) => _jobService.ilanEkle(
    userId: userId, origin: origin, destination: destination,
    loadType: loadType, weight: weight, truckType: truckType,
    price: price, companyName: companyName,
  );

  Future<void> ilanSil(String jobId) => _jobService.ilanSil(jobId);

  Future<void> isiTamamla(String jobId) => _jobService.isiTamamla(jobId);

  Stream<QuerySnapshot> kullaniciIlanlariniGetir(String uid) =>
      _jobService.kullaniciIlanlariniGetir(uid);

  // --- TEKLİF İŞLEMLERİ ---
  Stream<QuerySnapshot> ilanaGelenTeklifleriGetir(String jobId) =>
      _offerService.ilanaGelenTeklifleriGetir(jobId);

  Future<void> teklifVer({
    required String jobId,
    required double offerPrice,
    required String driverName,
    required String companyId,
    required String jobTitle,
  }) => _offerService.teklifVer(
    jobId: jobId, offerPrice: offerPrice,
    driverName: driverName, companyId: companyId, jobTitle: jobTitle,
  );

  Future<void> teklifiOnaylaVeBildirimGonder({
    required String jobId,
    required String offerId,
    required String driverId,
    required String jobTitle,
    required String driverName,
  }) => _offerService.teklifiOnaylaVeBildirimGonder(
    jobId: jobId, offerId: offerId,
    driverId: driverId, jobTitle: jobTitle, driverName: driverName,
  );

  Future<void> teklifDurumuGuncelle(String offerId, String status) =>
      _offerService.teklifDurumuGuncelle(offerId, status);

  // --- MESAJLAŞMA İŞLEMLERİ ---
  Future<String> sohbetBaslat(String otherUserId, String otherUserName) =>
      _chatService.sohbetBaslat(otherUserId, otherUserName);

  Future<void> mesajGonder(String chatId, String text) =>
      _chatService.mesajGonder(chatId, text);

  Stream<QuerySnapshot> sohbetleriDinle() => _chatService.sohbetleriDinle();

  // --- KULLANICI İŞLEMLERİ ---
  Future<dynamic> getUserData(String uid) => _userService.getUserData(uid);
}