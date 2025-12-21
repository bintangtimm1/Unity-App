import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';
import 'home_page.dart';
import 'add_post_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final int userId;
  const MainScreen({super.key, required this.username, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 🔥 1. BIKIN REMOTE CONTROL (GLOBAL KEY) 🔥
  // Pastikan class di HomePage namanya 'HomePageState' (tanpa underscore) sesuai Langkah 1
  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // 🔥 2. PASANG REMOTE CONTROL DI SINI (key: homeKey) 🔥
      HomePage(
        key: homeKey, // <-- INI PENTING!
        username: widget.username,
        userId: widget.userId,
      ),

      // Index 1: Community
      const Scaffold(
        body: Center(child: Text("Halaman Community", style: TextStyle(fontSize: 40))),
      ),

      // Index 2: Add Post Page
      AddPostPage(userId: widget.userId),

      // Index 3: Search
      const Scaffold(
        body: Center(child: Text("Halaman Search", style: TextStyle(fontSize: 40))),
      ),

      // Index 4: Profile Page
      ProfilePage(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // 🔥 3. LOGIC SAKTI: REFRESH HOME SAAT TOMBOL RUMAH DITEKAN 🔥
    if (index == 0) {
      // "Halo HomePage, tolong jalankan perintah fetchPosts() sekarang!"
      // Kita kasih delay dikit (100ms) biar transisi halusnya jalan dulu
      Future.delayed(const Duration(milliseconds: 100), () {
        homeKey.currentState?.fetchPosts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1080,
            height: 2424,
            child: Stack(
              children: [
                // Layer Bawah: Konten Halaman
                Positioned.fill(
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),

                // Layer Atas: Navbar
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: CustomNavbar(selectedIndex: _currentIndex, onItemTapped: _onItemTapped),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
