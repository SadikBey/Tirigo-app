import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';
import '../services/firebase_service.dart';
import 'post_job_screen.dart';
import 'offers_list_screen.dart';
import 'job_details_screen.dart';

class MyJobsScreen extends StatefulWidget {
  final TabController tabController;
  final String userRole;

  const MyJobsScreen({
    super.key,
    required this.tabController,
    required this.userRole,
  });

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  String get _userRole => widget.userRole;
  TabController get _tabController => widget.tabController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentUid.isEmpty
          ? const Center(child: Text("Lütfen giriş yapın."))
          : TabBarView(
              controller: _tabController,
              children: _userRole == 'company'
                  ? [
                      _buildList(
                        FirebaseFirestore.instance.collection('jobs').where('userId', isEqualTo: _currentUid).where('status', isEqualTo: 'open').snapshots(),
                        isOwner: true, emptyMessage: "Yayında ilanınız yok.", emptyIcon: Icons.post_add_outlined,
                      ),
                      _buildList(
                        FirebaseFirestore.instance.collection('jobs').where('userId', isEqualTo: _currentUid).where('status', whereIn: ['closed', 'accepted']).snapshots(),
                        isOwner: true, emptyMessage: "Devam eden işiniz yok.", emptyIcon: Icons.local_shipping_outlined,
                      ),
                      _buildList(
                        FirebaseFirestore.instance.collection('jobs').where('userId', isEqualTo: _currentUid).where('status', isEqualTo: 'completed').snapshots(),
                        isOwner: true, emptyMessage: "Tamamlanan işiniz yok.", emptyIcon: Icons.history_outlined,
                      ),
                    ]
                  : [
                      _buildDriverPendingList(),
                      _buildList(
                        FirebaseFirestore.instance.collection('jobs').where('acceptedDriverId', isEqualTo: _currentUid).where('status', whereIn: ['closed', 'accepted']).snapshots(),
                        isOwner: false, emptyMessage: "Aktif işiniz yok.", emptyIcon: Icons.local_shipping_outlined,
                      ),
                      _buildList(
                        FirebaseFirestore.instance.collection('jobs').where('acceptedDriverId', isEqualTo: _currentUid).where('status', isEqualTo: 'completed').snapshots(),
                        isOwner: false, emptyMessage: "Tamamlanan işiniz yok.", emptyIcon: Icons.history_outlined,
                      ),
                    ],
            ),
    );
  }

  Widget _buildDriverPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('offers').where('driverId', isEqualTo: _currentUid).where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, offerSnap) {
        if (offerSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }
        final offers = offerSnap.data?.docs ?? [];
        if (offers.isEmpty) return _buildEmptyState("Bekleyen teklifiniz yok.", Icons.hourglass_empty_outlined);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offerData = offers[index].data() as Map<String, dynamic>;
            final String jobId = offerData['jobId'] ?? '';
            final String offeredPrice = offerData['offeredPrice']?.toString() ?? '0';
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
              builder: (context, jobSnap) {
                if (!jobSnap.hasData || !jobSnap.data!.exists) return const SizedBox();
                final jobData = jobSnap.data!.data() as Map<String, dynamic>;
                return _buildPendingOfferCard(jobData, jobId, offeredPrice);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPendingOfferCard(Map<String, dynamic> jobData, String jobId, String offeredPrice) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => JobDetailsScreen(jobData: jobData, jobId: jobId),
        )),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${jobData['origin']?.toUpperCase()} → ${jobData['destination']?.toUpperCase()}",
                      style: AppTextStyles.labelBold, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Teklifim", style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      Text("$offeredPrice ₺", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top, size: 12, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text("Yanıt Bekleniyor", style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(Stream<QuerySnapshot> stream, {required bool isOwner, required String emptyMessage, required IconData emptyIcon}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(emptyMessage, emptyIcon);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final jobDoc = snapshot.data!.docs[index];
            final jobData = jobDoc.data() as Map<String, dynamic>;
            return _buildJobCard(jobDoc.id, jobData, isOwner);
          },
        );
      },
    );
  }

  Widget _buildJobCard(String jobId, Map<String, dynamic> data, bool isOwner) {
    final String status = data['status'] ?? 'open';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildOwnerProfileBar(data['userId']),
          const Divider(height: 1, indent: 16, endIndent: 16),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => JobDetailsScreen(jobData: data, jobId: jobId),
            )),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${data['origin']?.toUpperCase()} ➔ ${data['destination']?.toUpperCase()}",
                                style: AppTextStyles.labelBold, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("${data['loadType'] ?? 'Yük'} | ${data['weight'] ?? '0'} Ton", style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Text("${data['price'] ?? '0'} ₺", style: AppTextStyles.price),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
            ),
          ),
          if (isOwner) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOfferButton(jobId, data),
                  IconButton(
                    onPressed: () => _confirmDelete(jobId),
                    icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerProfileBar(String? userId) {
    if (userId == null || userId.isEmpty) return const SizedBox();
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String name = "Bilinmiyor";
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          var uData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = uData['firstName'] ?? '';
          final lastName = uData['lastName'] ?? '';
          final fullName = "$firstName $lastName".trim();
          name = fullName.isNotEmpty ? fullName : (uData['name'] ?? uData['companyName'] ?? "Bilinmiyor");
          photoUrl = uData['photoUrl'];
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: Colors.blueGrey[50],
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 14, color: AppColors.textSecondary) : null,
              ),
              const SizedBox(width: 8),
              Text(name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 14, color: AppColors.textHint),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfferButton(String jobId, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.ilanaGelenTeklifleriGetir(jobId),
      builder: (context, offerSnapshot) {
        int offerCount = offerSnapshot.hasData ? offerSnapshot.data!.docs.length : 0;
        return TextButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => OffersListScreen(jobId: jobId, jobTitle: "${data['origin']} - ${data['destination']}"),
          )),
          icon: Icon(Icons.local_offer, size: 16, color: offerCount > 0 ? AppColors.success : AppColors.textSecondary),
          label: Text("$offerCount Teklif",
              style: TextStyle(color: offerCount > 0 ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;
    switch (status) {
      case 'open': color = AppColors.success; text = "YAYINDA"; icon = Icons.radio_button_checked; break;
      case 'closed': case 'accepted': color = AppColors.info; text = "YOLDA"; icon = Icons.local_shipping; break;
      case 'completed': color = AppColors.textHint; text = "BİTTİ"; icon = Icons.check_circle; break;
      default: color = AppColors.textHint; text = status.toUpperCase(); icon = Icons.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.textHint)),
        ],
      ),
    );
  }

  void _confirmDelete(String jobId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { _firebaseService.ilanSil(jobId); Navigator.pop(context); },
            child: const Text("Sil", style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
}