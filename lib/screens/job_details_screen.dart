import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';
import '../services/firebase_service.dart';
import '../models/job_model.dart';
import 'offers_list_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobData, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _priceController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  bool _isSending = false;
  String _driverName = "Şoför";
  bool _isOwner = false;
  bool _isLoadingData = true;
  late JobModel _job;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
      if (doc.exists && mounted) {
        setState(() {
          _job = JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          _isOwner = _job.userId == _currentUid;
          _priceController.text = _job.price.toInt().toString();
          _isLoadingData = false;
        });
        _loadDriverName();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadDriverName() async {
    if (_isOwner) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _driverName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
          if (_driverName.isEmpty) _driverName = "Şoför";
        });
      }
    } catch (e) {
      debugPrint("İsim yüklenemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    final bool isJobOnMe = _job.acceptedDriverId == _currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteSection(),
                  const SizedBox(height: 12),
                  _buildDetailsRow(),
                  const SizedBox(height: 12),
                  _buildCompanyRow(),
                  const SizedBox(height: 20),
                  if (_isOwner)
                    _buildOwnerAction()
                  else if (isJobOnMe && _job.status != 'completed')
                    _buildActiveJobPanel()
                  else if (_job.status == 'open')
                    _buildOfferPanel()
                  else if (_job.status == 'completed')
                    _buildStatusBanner("İş tamamlandı", AppColors.success, Icons.check_circle)
                  else
                    _buildStatusBanner("Bu ilan artık aktif değil", Colors.grey, Icons.lock),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── APPBAR ──
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.primary),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("İlan Detayı",
            style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          Text("${_job.origin} → ${_job.destination}",
            style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _job.status == 'open' ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _job.status == 'open' ? "Açık" : _job.status == 'completed' ? "Tamamlandı" : "Kapalı",
            style: TextStyle(
              color: _job.status == 'open' ? AppColors.success : Colors.grey,
              fontSize: 12, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── ROTA BÖLÜMÜ ──
  Widget _buildRouteSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Fiyat + rota üst satır
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Rota", style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              Text(
                "${_job.price.toInt()} ₺",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kalkış
          Row(
            children: [
              Column(
                children: [
                  Container(width: 10, height: 10,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                  Container(width: 1.5, height: 36, color: Colors.grey.withValues(alpha: 0.25)),
                  Container(width: 10, height: 10,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCityRow(_job.origin, "Kalkış"),
                    const SizedBox(height: 20),
                    _buildCityRow(_job.destination, "Varış"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCityRow(String city, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(city, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }

  // ── DETAY SATIRLARI ──
  Widget _buildDetailsRow() {
    return Row(
      children: [
        Expanded(child: _buildDetailChip(Icons.inventory_2_outlined, "Yük", _job.loadType)),
        const SizedBox(width: 8),
        Expanded(child: _buildDetailChip(Icons.fitness_center_outlined, "Ağırlık", "${_job.weight} T")),
        const SizedBox(width: 8),
        Expanded(child: _buildDetailChip(Icons.local_shipping_outlined, "Araç", _job.truckType)),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          const SizedBox(height: 2),
          Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── FİRMA SATIRI ──
  Widget _buildCompanyRow() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(_job.userId).get(),
      builder: (context, snapshot) {
        String name = _job.companyName;

        if (snapshot.hasData && snapshot.data!.exists) {
          final d = snapshot.data!.data() as Map<String, dynamic>;
          
          // Tüm olası isim alanlarını sırayla dene
          final firstName = d['firstName'] ?? '';
          final lastName = d['lastName'] ?? '';
          final fullName = "$firstName $lastName".trim();
          
          if (fullName.isNotEmpty) {
            name = fullName;
          } else if ((d['name'] ?? '').toString().isNotEmpty) {
            name = d['name'];
          } else if ((d['companyName'] ?? '').toString().isNotEmpty) {
            name = d['companyName'];
          } else if ((d['email'] ?? '').toString().isNotEmpty) {
            name = d['email'].toString().split('@')[0];
          }
        }

        // Hâlâ "Tirigo Üyesi" ise ve userId varsa kısa ID göster
        if (name == 'Tirigo Üyesi' || name.isEmpty) {
          name = "Kullanıcı #${_job.userId.substring(0, 6)}";
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16, backgroundColor: AppColors.primaryWithOpacity(0.08),
                child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary))),
              const Text("İlan sahibi",
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        );
      },
    );
  }

  // ── AKSİYON PANELLERİ ──

  Widget _buildOwnerAction() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.ilanaGelenTeklifleriGetir(widget.jobId),
      builder: (context, snap) {
        int count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => OffersListScreen(
              jobId: widget.jobId,
              jobTitle: "${_job.origin} - ${_job.destination}",
            ),
          )),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inbox_rounded, color: AppColors.textWhite, size: 20),
                    const SizedBox(width: 10),
                    const Text("Gelen Teklifler",
                      style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: count > 0 ? AppColors.secondary : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count > 0 ? "$count Teklif" : "Henüz yok",
                    style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveJobPanel() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.info, size: 18),
              SizedBox(width: 8),
              Text("Bu iş sizin üzerinizdedir",
                style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _showCompletionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("Teslim Ettim — Tamamla",
              style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Teklif Ver", style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text("Fiyatı düzenleyip teklif gönderebilirsiniz.",
          style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondaryWithOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Text("₺", style: TextStyle(fontSize: 22, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isSending ? null : _handleSendOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2))
                : const Text("Teklifi Gönder",
                    style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(String text, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ── DIALOG FONKSİYONLARI ──

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("İşi tamamla"),
        content: const Text("Yükü teslim ettiyseniz işi tamamlandı olarak işaretleyebilirsiniz. Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _handleCompleteJob(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Tamamlandı", style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteJob() async {
    setState(() => _isSending = true);
    try {
      await _firebaseService.isiTamamla(widget.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İş tamamlandı! 🎉"), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleSendOffer() async {
    setState(() => _isSending = true);
    try {
      double offerPrice = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
      await _firebaseService.teklifVer(
        jobId: widget.jobId,
        offerPrice: offerPrice,
        driverName: _driverName,
        companyId: _job.userId,
        jobTitle: "${_job.origin} → ${_job.destination}",
      );
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 56),
            const SizedBox(height: 12),
            const Text("Teklif Gönderildi", style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            const Text("Firma teklifinizi inceleyecek.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Tamam", style: AppTextStyles.buttonPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}