import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 1. IMPORT INI
import '../widgets/custom_navbar.dart';
import 'home/home_page.dart';
import 'post/add_post_page.dart';
import 'profile/profile_page.dart';
import 'communites/community/community_page.dart';
import 'search_page.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final int userId;
  const MainScreen({super.key, required this.username, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // REMOTE CONTROL (GLOBAL KEY)
  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // Index 0: Home Page
      HomePage(
        key: homeKey,
        username: widget.username,
        userId: widget.userId,
        onNavigateToProfileTab: () {
          _onItemTapped(4);
        },
      ),

      // Index 1: Community
      CommunityPage(userId: widget.userId),

      // Index 2: Add Post Page
      AddPostPage(userId: widget.userId),

      // Index 3: Search
      SearchPage(userId: widget.userId),

      // Index 4: Profile Page
      ProfilePage(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // LOGIC REFRESH HOME
    if (index == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        homeKey.currentState?.fetchPosts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),

            // Layer Atas: Navbar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomNavbar(selectedIndex: _currentIndex, onItemTapped: _onItemTapped),
            ),
          ],
        ),
      ),
    );
  }
}
