import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/constants.dart';
import 'home_screen.dart';
import 'my_jobs_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'post_job_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  String _userRole = 'driver';
  String? _userPhotoUrl;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _userRole = doc.data()?['role'] ?? 'driver';
        _userPhotoUrl = doc.data()?['photoUrl'];
      });
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsScreen(),
    );
  }

  List<Widget> get _pages => [
    const HomeScreen(),
    MyJobsScreen(tabController: _tabController, userRole: _userRole),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool showFab = _userRole == 'company' && (_selectedIndex == 0 || _selectedIndex == 1);

    return Scaffold(
      // ── ORTAK APPBAR ──
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: _buildAppBarTitle(),
        bottom: _selectedIndex == 1
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.secondary,
                indicatorWeight: 3,
                labelColor: AppColors.textWhite,
                unselectedLabelColor: AppColors.textWhiteLight,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: _userRole == 'company'
                    ? const [
                        Tab(text: "Yayında", icon: Icon(Icons.radio_button_checked, size: 16)),
                        Tab(text: "Devam Eden", icon: Icon(Icons.local_shipping, size: 16)),
                        Tab(text: "Tamamlanan", icon: Icon(Icons.check_circle, size: 16)),
                      ]
                    : const [
                        Tab(text: "Bekleyenler", icon: Icon(Icons.hourglass_top, size: 16)),
                        Tab(text: "Aktif", icon: Icon(Icons.local_shipping, size: 16)),
                        Tab(text: "Tamamlanan", icon: Icon(Icons.check_circle, size: 16)),
                      ],
              )
            : null,
            
        // ── YENİ DÜZENLENEN SOL KISIM (LEADING) ──
        leadingWidth: 130, // Yazının sığması için alanı genişlettik
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              _selectedIndex == 0 ? "Tirigo" :
              _selectedIndex == 1 ? "Tirigo" :
              _selectedIndex == 2 ? "Tirigo" : "Tirigo",
              style: const TextStyle(
                color: Color(0xFFF3722C), // Turuncu renk
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0, // Daha şık durması için harf arası boşluk
              ),
            ),
          ),
        ),

        actions: [
          // Bildirim ikonu
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('receiverId', isEqualTo: currentUid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasNotif = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textWhite, size: 26),
                    onPressed: _showNotifications,
                  ),
                  if (hasNotif)
                    Positioned(
                      right: 10, top: 10,
                      child: Container(width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                    ),
                ],
              );
            },
          ),
          // Profil avatarı
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                backgroundImage: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                    ? NetworkImage(_userPhotoUrl!) : null,
                child: (_userPhotoUrl == null || _userPhotoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 18, color: AppColors.textWhite) : null,
              ),
            ),
          ),
        ],
      ),

      body: IndexedStack(index: _selectedIndex, children: _pages),

      // ── İLAN EKLEME FAB (sadece şirket için) ──
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PostJobScreen())),
              backgroundColor: AppColors.secondary,
              icon: const Icon(Icons.add, color: AppColors.textWhite, size: 24),
              label: const Text("İlan Ekle",
                style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.backgroundCard,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Yük Bul'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'İşlerim'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return const Text("Yük Bul", style: AppTextStyles.appBarTitle);
      case 1: return Text(_userRole == 'company' ? "İlan Yönetimi" : "İşlerim", style: AppTextStyles.appBarTitle);
      case 2: return const Text("Mesajlar", style: AppTextStyles.appBarTitle);
      case 3: return const Text("Profil", style: AppTextStyles.appBarTitle);
      default: return const Text("Tirigo", style: AppTextStyles.appBarTitle);
    }
  }
}