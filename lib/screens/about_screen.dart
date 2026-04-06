import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Hakkımızda", style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo + isim
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.secondaryWithOpacity(0.3), blurRadius: 16)],
                    ),
                    child: const Center(
                      child: Icon(Icons.local_shipping_rounded, color: AppColors.textWhite, size: 44),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text("Tirigo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Text("Lojistik Platformu", style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.secondaryWithOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Versiyon 1.0.0", style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSection("Tirigo Nedir?",
              "Tirigo, yük sahipleri ile nakliyecileri buluşturan modern bir lojistik platformudur. Firmalar yük ilanı yayınlar, sürücüler teklif verir ve en uygun anlaşma gerçekleşir."),
            _buildSection("Misyonumuz",
              "Türkiye'nin lojistik sektörünü dijitalleştirmek, şeffaf fiyatlandırma ile hem firmalara hem de sürücülere değer katmak."),
            _buildSection("Vizyonumuz",
              "Lojistik sektöründe güvenilirlik ve hız standartlarını yeniden tanımlamak; Türkiye'nin en büyük nakliye eşleştirme platformu olmak."),
            _buildSection("İletişim",
              "Herhangi bir sorunuz veya geri bildiriminiz için bizimle iletişime geçebilirsiniz.\n\ndestek@tirigo.com"),

            const SizedBox(height: 20),
            const Center(
              child: Text("© 2025 Tirigo. Tüm hakları saklıdır.",
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}