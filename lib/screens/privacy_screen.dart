import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Gizlilik & Güvenlik", style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 48),
              ),
            ),
            const SizedBox(height: 20),

            _buildSection("Veri Güvenliği",
              "Kişisel bilgileriniz 256-bit SSL şifreleme ile korunmaktadır. Verilerinize yalnızca yetkili personel erişebilir ve üçüncü taraflarla paylaşılmaz."),
            _buildSection("Kişisel Verilerin Korunması",
              "6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında verileriniz toplanmakta, işlenmekte ve saklanmaktadır. Verilerinizin silinmesini talep etmek için destek@tirigo.com adresine başvurabilirsiniz."),
            _buildSection("Çerez Politikası",
              "Uygulamamız, deneyiminizi iyileştirmek amacıyla çerezler kullanmaktadır. Oturum çerezleri giriş bilgilerinizi geçici olarak saklar ve oturumunuz kapandığında silinir."),
            _buildSection("Konum Verileri",
              "Konum bilginiz yalnızca güzergah eşleştirmesi için kullanılır. İzin vermediğiniz sürece konum verileriniz işlenmez."),
            _buildSection("Hesap Silme",
              "Hesabınızı kalıcı olarak silmek ve tüm verilerinizin sistemden kaldırılmasını talep etmek için destek@tirigo.com adresine e-posta gönderebilirsiniz."),

            const SizedBox(height: 20),
            const Center(
              child: Text("Son güncelleme: Ocak 2025",
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}