import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // 1. Firestore bağlantısını kuruyoruz
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 2. 'ilanlar' koleksiyonuna referans oluşturuyoruz (Kod tekrarını önler)
  CollectionReference get _ilanlarRef => _firestore.collection('ilanlar');

  // --- İLAN EKLEME FONKSİYONU ---
  Future<void> ilanEkle({
    required String baslik,
    required String aciklama,
    required String nereden,
    required String nereye,
    required double fiyat,
    required String ilanSahibi, // İlanı kimin verdiğini bilmek önemli
  }) async {
    try {
      await _ilanlarRef.add({
        'baslik': baslik,
        'aciklama': aciklama,
        'nereden': nereden,
        'nereye': nereye,
        'fiyat': fiyat,
        'ilanSahibi': ilanSahibi,
        'olusturmaTarihi': FieldValue.serverTimestamp(), // Otomatik tarih
        'aktifMi': true, // İlanın yayında olup olmadığını kontrol etmek için
      });
      print("İlan başarıyla Firestore'a kaydedildi.");
    } catch (e) {
      print("İlan eklenirken hata oluştu: $e");
      rethrow; 
    }
  }

  // --- İLANLARI LİSTELEME FONKSİYONU (GÜNCEL) ---
  // Bu fonksiyon ilanları tarihe göre sıralı bir şekilde getirir
  Stream<QuerySnapshot> ilanlariGetir() {
    return _ilanlarRef
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots();
  }

  // --- İLAN SİLME FONKSİYONU (İLERİDE LAZIM OLACAK) ---
  Future<void> ilanSil(String docId) async {
    try {
      await _ilanlarRef.doc(docId).delete();
    } catch (e) {
      print("Silme hatası: $e");
    }
  }
}