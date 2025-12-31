import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Gizlilik ve Güvenlik', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle("Hesap Güvenliği"),
          _buildSecurityTile(
            Icons.lock_outline, 
            "Şifre Değiştir", 
            "Hesap şifrenizi güncelleyin", 
            onTap: () {}
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: Color(0xFF1B263B)),
            title: const Text("Biyometrik Giriş"),
            subtitle: const Text("Parmak izi veya yüz tanıma kullan"),
            value: _biometricEnabled,
            activeColor: const Color(0xFFF3722C),
            onChanged: (bool value) => setState(() => _biometricEnabled = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.verified_user_outlined, color: Color(0xFF1B263B)),
            title: const Text("İki Adımlı Doğrulama"),
            subtitle: const Text("Girişlerde SMS onayı iste"),
            value: _twoFactorEnabled,
            activeColor: const Color(0xFFF3722C),
            onChanged: (bool value) => setState(() => _twoFactorEnabled = value),
          ),
          
          const Divider(height: 40),
          _buildSectionTitle("Veri ve Gizlilik"),
          _buildSecurityTile(
            Icons.visibility_outlined, 
            "Gizlilik Politikası", 
            "Verilerinizin nasıl işlendiğini görün", 
            onTap: () {}
          ),
          _buildSecurityTile(
            Icons.description_outlined, 
            "Kullanım Koşulları", 
            "Uygulama kullanım kuralları", 
            onTap: () {}
          ),
          _buildSecurityTile(
            Icons.share_location_outlined, 
            "Konum Paylaşımı", 
            "Sadece aktif sefer sırasında paylaşılır", 
            onTap: () {}
          ),

          const SizedBox(height: 30),
          // Tehlikeli Bölge
          _buildSectionTitle("Hesap Yönetimi"),
          Card(
            elevation: 0,
            color: Colors.red.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.withOpacity(0.2))
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Hesabımı Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: const Text("Tüm verileriniz kalıcı olarak silinir"),
              onTap: () => _showDeleteDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  // Başlık yardımcı widget'ı
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: Color(0xFF1B263B)
        ),
      ),
    );
  }

  // Liste elemanı yardımcı widget'ı
  Widget _buildSecurityTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B263B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // Hesap silme onay kutusu
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Hesabınızı sildiğinizde bekleyen ödemeleriniz ve geçmiş seferleriniz dahil tüm verileriniz kaybolur."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () {}, 
            child: const Text("Evet, Hesabı Sil", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}