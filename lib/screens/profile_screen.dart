import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';
import 'login_screen.dart';
import 'payment_screen.dart';
import 'documents_screen.dart';
import 'vehicles_screen.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _isOwnProfile =>
      widget.userId == null ||
      widget.userId == FirebaseAuth.instance.currentUser?.uid;

  Future<void> _updateField(String fieldKey, String label, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$label Güncelle", style: AppTextStyles.heading3),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Yeni $label giriniz",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .update({fieldKey: controller.text.trim()});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Kaydet", style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _showRatingSheet(String targetId) {
    int selectedStars = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            left: 24, right: 24, top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Hizmeti Değerlendir", style: AppTextStyles.heading3),
              const SizedBox(height: 6),
              const Text("Deneyiminizi paylaşın",
                style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setModalState(() => selectedStars = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < selectedStars ? AppColors.warning : Colors.grey[300],
                      size: 46,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Text(
                ["Yıldız seçin", "Kötü 😕", "Orta 😐", "İyi 🙂", "Çok İyi 😊", "Mükemmel! 🌟"][selectedStars],
                style: TextStyle(
                  color: selectedStars == 0 ? AppColors.textHint : AppColors.warning,
                  fontWeight: FontWeight.bold, fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStars == 0 ? Colors.grey[300] : AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: selectedStars == 0 ? null : () async {
                    final ref = FirebaseFirestore.instance.collection('users').doc(targetId);
                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                      final snap = await transaction.get(ref);
                      if (!snap.exists) return;
                      final data = snap.data() as Map<String, dynamic>;
                      transaction.update(ref, {
                        'totalRating': (data['totalRating'] ?? 0).toDouble() + selectedStars,
                        'ratingCount': (data['ratingCount'] ?? 0).toInt() + 1,
                      });
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Değerlendirme gönderildi! ⭐"),
                        backgroundColor: AppColors.success,
                      ));
                    }
                  },
                  child: const Text("Gönder", style: AppTextStyles.buttonPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String targetId =
        widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          if (!snapshot.data!.exists) return const Center(child: Text("Kullanıcı bulunamadı."));

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String firstName = userData['firstName'] ?? '';
          final String lastName = userData['lastName'] ?? '';
          final String fullName = "$firstName $lastName".trim();
          final bool isCompany = userData['role'] == 'company';
          final double total = (userData['totalRating'] ?? 0).toDouble();
          final int ratingCount = (userData['ratingCount'] ?? 0).toInt();
          final double avg = ratingCount > 0 ? total / ratingCount : 0.0;

          return SafeArea(
            child: Column(
              children: [
                // ── ÜSTTE AppBar ──
                _buildAppBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ── KÜÇÜK HEADER ──
                        _buildCompactHeader(fullName, avg, isCompany, targetId),

                        const SizedBox(height: 20),

                        // ── MENÜ LİSTESİ ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if (_isOwnProfile) ...[
                                _buildMenuTile(
                                  icon: Icons.payment_outlined,
                                  title: "Ödeme Bilgileri",
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                                  showEdit: true,
                                ),
                                _buildMenuTile(
                                  icon: Icons.description_outlined,
                                  title: "Dökümanlarım",
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen())),
                                  showEdit: true,
                                ),
                              ],

                              if (!_isOwnProfile) ...[
                                _buildMenuTile(
                                  icon: Icons.star_outline_rounded,
                                  iconColor: AppColors.warning,
                                  title: "Puan Ver & Değerlendir",
                                  onTap: () => _showRatingSheet(targetId),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Kişisel Bilgiler
                              _buildSectionLabel("Kişisel Bilgiler"),
                              _buildMenuTile(
                                icon: Icons.person_outline_rounded,
                                title: "Ad Soyad",
                                subtitle: fullName.isEmpty ? "Henüz girilmedi" : fullName,
                                onTap: _isOwnProfile ? () => _showEditPersonalDialog(userData) : null,
                                showEdit: _isOwnProfile,
                              ),
                              _buildMenuTile(
                                icon: Icons.phone_outlined,
                                title: "Telefon",
                                subtitle: userData['phone'] ?? "Henüz girilmedi",
                                onTap: _isOwnProfile ? () => _updateField("phone", "Telefon", userData['phone'] ?? "") : null,
                                showEdit: _isOwnProfile,
                              ),
                              _buildMenuTile(
                                icon: Icons.location_city_outlined,
                                title: "Şehir",
                                subtitle: userData['city'] ?? "Henüz girilmedi",
                                onTap: _isOwnProfile ? () => _updateField("city", "Şehir", userData['city'] ?? "") : null,
                                showEdit: _isOwnProfile,
                              ),

                              if (isCompany) ...[
                                const SizedBox(height: 20),
                                _buildSectionLabel("Kurumsal Bilgiler"),
                                _buildMenuTile(
                                  icon: Icons.business_rounded,
                                  title: "Şirket Adı",
                                  subtitle: userData['companyName'] ?? "Henüz girilmedi",
                                  onTap: _isOwnProfile ? () => _updateField("companyName", "Şirket Adı", userData['companyName'] ?? "") : null,
                                  showEdit: _isOwnProfile,
                                ),
                                _buildMenuTile(
                                  icon: Icons.receipt_long_outlined,
                                  title: "Vergi No",
                                  subtitle: userData['taxNumber'] ?? "Henüz girilmedi",
                                  onTap: _isOwnProfile ? () => _updateField("taxNumber", "Vergi No", userData['taxNumber'] ?? "") : null,
                                  showEdit: _isOwnProfile,
                                ),
                              ],

                              if (!isCompany) ...[
                                const SizedBox(height: 20),
                                _buildSectionLabel("Araç Bilgileri"),
                                _buildMenuTile(
                                  icon: Icons.local_shipping_outlined,
                                  title: "Araçlarım",
                                  subtitle: "Araçlarınızı yönetin",
                                  onTap: _isOwnProfile ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen())) : null,
                                  showEdit: _isOwnProfile,
                                ),
                              ],

                              const SizedBox(height: 20),
                              _buildSectionLabel("Diğer"),
                              _buildMenuTile(
                                icon: Icons.info_outline_rounded,
                                title: "Hakkımızda",
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                                showEdit: true,
                              ),
                              _buildMenuTile(
                                icon: Icons.security_outlined,
                                title: "Gizlilik & Güvenlik",
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                                showEdit: true,
                              ),

                              const SizedBox(height: 30),

                              // ── ÇIKIŞ BUTONU ──
                              if (_isOwnProfile)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () => FirebaseAuth.instance.signOut().then(
                                      (_) => Navigator.pushAndRemoveUntil(context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                                    ),
                                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                                    label: const Text("Çıkış Yap",
                                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── APPBAR ──
  Widget _buildAppBar(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  // ── KÜÇÜK HEADER ──
  Widget _buildCompactHeader(String fullName, double avg, bool isCompany, String targetId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('acceptedDriverId', isEqualTo: targetId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, jobSnap) {
        int seferCount = jobSnap.data?.docs.length ?? 0;

        return Container(
  margin: EdgeInsets.zero, // Yanlardaki boşluğu tamamen kaldırır
  decoration: const BoxDecoration(
    color: AppColors.primary,
    // Kartın üst köşelerini düz, alt köşelerini oval yaparak tam header görünümü sağlar
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(24), 
    ),
  ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.secondaryWithOpacity(0.4),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                          style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // İsim + Puan + Rozet
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? "İsimsiz Kullanıcı" : fullName,
                            style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(
                                i < avg.floor()
                                    ? Icons.star_rounded
                                    : (i < avg && avg - i >= 0.5)
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                color: i < avg.ceil()
                                    ? AppColors.secondary
                                    : Colors.white24,
                                size: 15,
                              )),
                              const SizedBox(width: 4),
                              Text(
                                avg.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textWhiteLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryWithOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.secondaryWithOpacity(0.3)),
                            ),
                            child: Text(
                              isCompany ? "🏢 Şirket" : "🚛 Sürücü",
                              style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sefer sayısı
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$seferCount",
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const Text(
                          "Sefer",
                          style: TextStyle(fontSize: 11, color: AppColors.textWhiteLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Alt turuncu çizgi
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.secondaryWithOpacity(0.25),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── BÖLÜM ETİKETİ ──
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
            color: AppColors.textSecondary, letterSpacing: 0.5)),
    );
  }

  // ── MENÜ TILE ──
  Widget _buildMenuTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showEdit = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(title, style: AppTextStyles.labelBold),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: showEdit
            ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showEditPersonalDialog(Map<String, dynamic> userData) {
    final firstNameCtrl = TextEditingController(text: userData['firstName'] ?? '');
    final lastNameCtrl = TextEditingController(text: userData['lastName'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              const Text("Kişisel Bilgiler", style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              const Text("Ad", style: AppTextStyles.labelSmall),
              const SizedBox(height: 6),
              TextField(
                controller: firstNameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: "Adınız",
                  filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              const Text("Soyad", style: AppTextStyles.labelSmall),
              const SizedBox(height: 6),
              TextField(
                controller: lastNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: "Soyadınız",
                  filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;
                    final first = firstNameCtrl.text.trim();
                    final last = lastNameCtrl.text.trim();
                    if (first.isEmpty && last.isEmpty) return;
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'firstName': first,
                      'lastName': last,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Kaydet", style: AppTextStyles.buttonPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}