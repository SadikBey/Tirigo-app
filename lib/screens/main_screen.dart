import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_jobs_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex; 
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Görüntülenecek sayfalar
  final List<Widget> _pages = [
    const HomeScreen(),      // İndeks 0 (AppBar burada olacak)
    const MyJobsScreen(),    // İndeks 1
    const MessagesScreen(),  // İndeks 2
    const ProfileScreen(),   // İndeks 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar buradan tamamen kaldırıldı. 
      // Her sayfa kendi Scaffold'u içinde kendi AppBar'ını yönetebilir.
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFF3722C), // Tirigo Turuncusu
        unselectedItemColor: Colors.blueGrey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}