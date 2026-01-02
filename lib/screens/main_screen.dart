import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_jobs_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  // Dışarıdan hangi sekmenin açılacağını belirlemek için index alıyoruz
  final int initialIndex; 

  const MainScreen({super.key, this.initialIndex = 0}); // Varsayılan değer 0 (Yük Bul)

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Seçili olan sekmenin indeksi
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Uygulama açıldığında veya yönlendirme yapıldığında gelen indexi ata
    _selectedIndex = widget.initialIndex;
  }

  // Navigasyon çubuğundaki her bir seçenek için görüntülenecek sayfalar
  final List<Widget> _pages = [
    const HomeScreen(),      // Yük Akışı (Feed) - İndeks 0
    const MyJobsScreen(),    // İşlerim / İlanlarım - İndeks 1
    const MessagesScreen(),  // Mesajlaşma - İndeks 2
    const ProfileScreen(),   // Profil ve Ayarlar - İndeks 3
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
      // IndexedStack kullanarak sayfalar arası geçişte verilerin kaybolmasını önlüyoruz
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFF3722C), // Tirigo Turuncusu
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
            activeIcon: Icon(Icons.person), // İkon düzeltildi
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}