import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Google ile giriş yap
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Kullanıcıdan Google hesabı seçmesini iste
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı seçim yapmadan geri çıktıysa

      // 2. Seçilen hesaptan kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Bu detaylarla Firebase için bir kimlik belgesi (Credential) oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase'e bu belgeyle giriş yap
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 5. Kullanıcı veritabanında yoksa yeni kullanıcı olarak ekle
      await _createOrUpdateUser(userCredential.user!);

      return userCredential.user;
    } catch (e) {
      print("Google Giriş Hatası: $e");
      return null;
    }
  }

  /// Kullanıcıyı Firestore'da oluştur veya güncelle
  Future<void> _createOrUpdateUser(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Yeni kullanıcı
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'role': 'driver', // Varsayılan olarak driver
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Mevcut kullanıcıyı güncelle
        await userDoc.update({
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Kullanıcı oluşturma/güncelleme hatası: $e");
    }
  }

  /// Çıkış yapma fonksiyonu
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Çıkış hatası: $e");
    }
  }

  /// Mevcut kullanıcı döndür
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Kullanıcı rolünü getir
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      print("Rol getirme hatası: $e");
      return null;
    }
  }
}
