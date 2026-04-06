import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Araçlarım", style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}",
                style: const TextStyle(color: AppColors.error)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Henüz araç eklemediniz.",
                      style: TextStyle(color: AppColors.textHint, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("Sağ alttaki + butonuna basın.",
                      style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _buildVehicleCard(data, docId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleSheet(context, null, null),
        backgroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: AppColors.textWhite, size: 28),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> data, String docId) {
    final String plate = data['plate'] ?? '-';
    final String truckType = data['truckType'] ?? '-';
    final String capacity = data['capacity'] ?? '-';
    final bool isActive = data['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: Plaka + Durum + X butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(plate,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? "Aktif" : "Pasif",
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.success : AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _confirmDelete(docId),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: AppColors.textWhite, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bilgi satırları
          _buildInfoRow("Araç Tipi", truckType),
          const SizedBox(height: 6),
          _buildInfoRow("Kapasite", "$capacity Ton"),

          const SizedBox(height: 16),

          // Düzenle butonu
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _showVehicleSheet(context, data, docId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Düzenle",
                  style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }

  void _showVehicleSheet(BuildContext context, Map<String, dynamic>? existing, String? docId) {
    final plateCtrl = TextEditingController(text: existing?['plate'] ?? '');
    final capacityCtrl = TextEditingController(text: existing?['capacity'] ?? '');
    String selectedType = existing?['truckType'] ?? 'Tenteli Tır';
    final types = ['Tenteli Tır', 'Kamyon', 'Onteker', 'Panelvan', 'Kırkayak', 'Frigorifik'];
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                Text(existing == null ? "Yeni Araç Ekle" : "Aracı Düzenle", style: AppTextStyles.heading3),
                const SizedBox(height: 20),

                const Text("Plaka", style: AppTextStyles.labelBold),
                const SizedBox(height: 8),
                TextField(
                  controller: plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "34 ABC 345",
                    prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Araç Tipi", style: AppTextStyles.labelBold),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: types.map((t) {
                    final selected = selectedType == t;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t, style: TextStyle(
                          color: selected ? AppColors.textWhite : AppColors.textPrimary,
                          fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                const Text("Kapasite (Ton)", style: AppTextStyles.labelBold),
                const SizedBox(height: 8),
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Örn: 22",
                    prefixIcon: const Icon(Icons.fitness_center_outlined, color: AppColors.primary),
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (plateCtrl.text.trim().isEmpty || capacityCtrl.text.trim().isEmpty) return;
                      setModalState(() => isLoading = true);
                      final vehicleData = {
                        'ownerId': uid,
                        'plate': plateCtrl.text.trim().toUpperCase(),
                        'truckType': selectedType,
                        'capacity': capacityCtrl.text.trim(),
                        'isActive': true,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };
                      if (docId != null) {
                        await FirebaseFirestore.instance.collection('vehicles').doc(docId).update(vehicleData);
                      } else {
                        vehicleData['createdAt'] = FieldValue.serverTimestamp();
                        await FirebaseFirestore.instance.collection('vehicles').add(vehicleData);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: isLoading
                        ? const CircularProgressIndicator(color: AppColors.textWhite)
                        : Text(existing == null ? "Araç Ekle" : "Kaydet",
                            style: AppTextStyles.buttonPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Aracı Sil"),
        content: const Text("Bu aracı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('vehicles').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
}