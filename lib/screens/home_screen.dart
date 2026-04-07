import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/constants.dart';
import '../models/job_model.dart';
import 'job_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _originSearchController = TextEditingController();
  final TextEditingController _destSearchController = TextEditingController();
  String _originFilter = "";
  String _destFilter = "";
  String _selectedLoadType = "Hepsi";
  String _selectedVehicleType = "Hepsi";

  final List<String> _loadTypes = ["Hepsi", "Gıda", "Demir", "Tekstil", "İnşaat", "Kimyasal", "Mobilya"];
  final List<String> _vehicleTypes = ["Hepsi", "Tenteli Tır", "Kamyon", "Onteker", "Panelvan", "Kırkayak"];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _originSearchController.dispose();
    _destSearchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filtrele", style: AppTextStyles.heading2),
                  TextButton(
                    onPressed: () {
                      setModalState(() { _selectedLoadType = "Hepsi"; _selectedVehicleType = "Hepsi"; });
                      setState(() { _selectedLoadType = "Hepsi"; _selectedVehicleType = "Hepsi"; });
                    },
                    child: const Text("Sıfırla", style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text("Yük Cinsi", style: AppTextStyles.labelBold),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _loadTypes.map((type) {
                  bool isSelected = _selectedLoadType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: AppColors.secondary,
                    labelStyle: TextStyle(color: isSelected ? AppColors.textWhite : AppColors.textPrimary),
                    onSelected: (_) { setModalState(() => _selectedLoadType = type); setState(() => _selectedLoadType = type); },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text("Araç Tipi", style: AppTextStyles.labelBold),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _vehicleTypes.map((type) {
                  bool isSelected = _selectedVehicleType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? AppColors.textWhite : AppColors.textPrimary),
                    onSelected: (_) { setModalState(() => _selectedVehicleType = type); setState(() => _selectedVehicleType = type); },
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("SONUÇLARI GÖSTER", style: AppTextStyles.buttonPrimary),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopSearchArea(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').where('status', isEqualTo: 'open').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool matchesSearch = (data['origin'] ?? "").toString().toLowerCase().contains(_originFilter.toLowerCase()) &&
                      (data['destination'] ?? "").toString().toLowerCase().contains(_destFilter.toLowerCase());
                  bool matchesLoad = (_selectedLoadType == "Hepsi") || ((data['loadType'] ?? "") == _selectedLoadType);
                  bool matchesVehicle = (_selectedVehicleType == "Hepsi") || ((data['truckType'] ?? "") == _selectedVehicleType);
                  return matchesSearch && matchesLoad && matchesVehicle;
                }).toList();

                if (filteredDocs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    JobModel job = JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                    return _buildJobCard(context, job);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchArea() {
    bool hasActiveFilter = _selectedLoadType != "Hepsi" || _selectedVehicleType != "Hepsi";
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 16),
      color: AppColors.backgroundLight,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  _buildSearchField(_originSearchController, 'Nereden?', (val) => setState(() => _originFilter = val)),
                  const Icon(Icons.swap_horiz, size: 18, color: AppColors.textHint),
                  _buildSearchField(_destSearchController, 'Nereye?', (val) => setState(() => _destFilter = val)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasActiveFilter ? AppColors.secondary : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.primaryWithOpacity(0.3), blurRadius: 6)],
              ),
              child: const Icon(Icons.tune, color: AppColors.textWhite, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hint, Function(String) onChanged) {
    return Expanded(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(jobData: job.toMap(), jobId: job.id))),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 4),
                        Flexible(child: Text(job.origin.toUpperCase(), style: AppTextStyles.route)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, color: AppColors.textHint, size: 14)),
                        Flexible(child: Text(job.destination.toUpperCase(), style: AppTextStyles.route)),
                      ],
                    ),
                  ),
                  Text('${job.price.toInt()} ₺', style: AppTextStyles.price),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('${job.loadType} | ${job.weight} Ton', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildMiniProfileBar(job),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniProfileBar(JobModel job) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(job.userId).get(),
      builder: (context, snapshot) {
        String name = job.companyName;
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          var uData = snapshot.data!.data() as Map<String, dynamic>;
          name = uData['name'] ?? uData['userName'] ?? job.companyName;
          photoUrl = uData['photoUrl'];
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: Colors.blueGrey[50],
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 14, color: AppColors.textSecondary) : null,
              ),
              const SizedBox(width: 8),
              Text(name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              const Text('Detayları Gör >', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Sonuç bulunamadı.", style: TextStyle(color: AppColors.textHint)),
        ],
      ),
    );
  }
}