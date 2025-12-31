import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Yardım ve Destek', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst Mavi Bölüm ve Arama Çubuğu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1B263B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Size nasıl yardımcı olabiliriz?",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Sorun veya anahtar kelime ara...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1B263B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Hızlı İletişim Butonları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildContactCard(
                    context,
                    "Canlı Destek",
                    Icons.chat_bubble_outline,
                    const Color(0xFFF3722C),
                  ),
                  const SizedBox(width: 15),
                  _buildContactCard(
                    context,
                    "Bizi Arayın",
                    Icons.headset_mic_outlined,
                    const Color(0xFF1B263B),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Sıkça Sorulan Sorular Başlığı
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sıkça Sorulan Sorular",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B263B)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // SSS Listesi
            _buildFAQItem("Ödememi ne zaman alırım?", "Sefer tamamlanıp alıcı onayı verdikten sonra 24 saat içinde hesabınıza aktarılır."),
            _buildFAQItem("Yük iptali nasıl yapılır?", "Aktif seferlerim menüsünden iptal talebi oluşturabilirsiniz."),
            _buildFAQItem("Belgelerim neden onaylanmadı?", "Görüntü kalitesi düşük veya süresi dolmuş belgeler reddedilebilir."),
            _buildFAQItem("Komisyon oranları nedir?", "Tirigo, başarılı her seferden %5 hizmet bedeli almaktadır."),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // İletişim Kartı Widget'ı
  Widget _buildContactCard(BuildContext context, String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // FAQ Item Widget'ı (ExpansionTile)
  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}