import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_jobs_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Seçili olan sekmenin indeksi (0: Ana Sayfa)
  int _selectedIndex = 0;

  // Navigasyon çubuğundaki her bir seçenek için görüntülenecek sayfalar
  final List<Widget> _pages = [
    const HomeScreen(),      // Yük Akışı (Feed)
    const MyJobsScreen(),    // İşlerim / Tekliflerim
    const MessagesScreen(),  // Mesajlaşma
    const ProfileScreen(),   // Profil ve Ayarlar
  ];

  // Sekme değiştirme fonksiyonu
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack kullanarak sayfalar arası geçişte verilerin kaybolmasını (scroll pozisyonu vb.) önlüyoruz
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // 4 ikon olduğu için sabit tip
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFF3722C), // Tasarımdaki Tirigo Turuncusu
        unselectedItemColor: Colors.blueGrey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Yük Bul',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'İşlerim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            activeIcon: Icon(Icons.abc_outlined),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}      