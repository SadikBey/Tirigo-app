import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/constants.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _picker = ImagePicker();

  final List<Map<String, dynamic>> _docTypes = [
    {'key': 'license', 'label': 'Ehliyet', 'icon': Icons.badge_outlined, 'desc': 'Sürücü ehliyetinizin net fotoğrafı'},
    {'key': 'registration', 'label': 'Ruhsat', 'icon': Icons.article_outlined, 'desc': 'Araç ruhsatının ön ve arka yüzü'},
    {'key': 'src', 'label': 'SRC Belgesi', 'icon': Icons.workspace_premium_outlined, 'desc': 'Mesleki yeterlilik belgesi'},
    {'key': 'insurance', 'label': 'Sigorta', 'icon': Icons.security_outlined, 'desc': 'Geçerli araç sigortası poliçesi'},
  ];

  Map<String, dynamic> _uploadStatus = {};
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('documents').doc(uid).get();
    if (mounted) {
      setState(() {
        _uploadStatus = doc.exists ? (doc.data() ?? {}) : {};
        _isFetching = false;
      });
    }
  }

  Future<void> _uploadFromCamera(String docKey) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) await _uploadFile(docKey, File(picked.path));
  }

  Future<void> _uploadFromGallery(String docKey) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) await _uploadFile(docKey, File(picked.path));
  }

  Future<void> _uploadFromFiles(String docKey) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result != null && result.files.single.path != null) {
      await _uploadFile(docKey, File(result.files.single.path!));
    }
  }

  Future<void> _uploadFile(String docKey, File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadStatus['${docKey}_uploading'] = true);

    try {
      final ref = FirebaseStorage.instance.ref('documents/$uid/$docKey');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('documents').doc(uid).set({
        docKey: {'url': url, 'status': 'pending', 'uploadedAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));

      setState(() {
        _uploadStatus[docKey] = {'url': url, 'status': 'pending'};
        _uploadStatus.remove('${docKey}_uploading');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Belge yüklendi, inceleme bekliyor."), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() => _uploadStatus.remove('${docKey}_uploading'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yükleme hatası: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showUploadOptions(String docKey, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            Text("$label Yükle", style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            const Text("Belgeyi nasıl yüklemek istersiniz?",
              style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _uploadOption(Icons.camera_alt_outlined, "Kamera", () {
                  Navigator.pop(context);
                  _uploadFromCamera(docKey);
                })),
                const SizedBox(width: 12),
                Expanded(child: _uploadOption(Icons.photo_library_outlined, "Galeri", () {
                  Navigator.pop(context);
                  _uploadFromGallery(docKey);
                })),
                const SizedBox(width: 12),
                Expanded(child: _uploadOption(Icons.folder_outlined, "Dosyalar", () {
                  Navigator.pop(context);
                  _uploadFromFiles(docKey);
                })),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primaryWithOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryWithOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Dökümanlarım", style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgi bandı
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryWithOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.secondaryWithOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Yüklenen belgeler Tirigo ekibi tarafından incelenir. Onay süreci 24 saat içinde tamamlanır.",
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Döküman kartları
                  ..._docTypes.map((doc) => _buildDocCard(doc)),
                ],
              ),
            ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final String key = doc['key'];
    final docData = _uploadStatus[key] as Map<String, dynamic>?;
    final bool isUploading = _uploadStatus['${key}_uploading'] == true;
    final String status = docData?['status'] ?? 'missing';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = "Onaylandı";
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top_rounded;
        statusText = "İnceleniyor";
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = "Reddedildi";
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.upload_file_outlined;
        statusText = "Yüklenmedi";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        border: status == 'missing' ? Border.all(color: Colors.grey.withValues(alpha: 0.2)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(doc['icon'] as IconData, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc['label'] as String, style: AppTextStyles.labelBold),
                  const SizedBox(height: 3),
                  Text(doc['desc'] as String, style: AppTextStyles.labelSmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isUploading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                : GestureDetector(
                    onTap: () => _showUploadOptions(key, doc['label'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.secondaryWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        status == 'approved' ? Icons.refresh : Icons.upload_rounded,
                        color: status == 'approved' ? AppColors.success : AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}