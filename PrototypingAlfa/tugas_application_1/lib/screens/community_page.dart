import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'add_community_page.dart';

class CommunityPage extends StatefulWidget {
  final int userId;
  const CommunityPage({super.key, required this.userId});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _userTier = 'regular'; // Default regular
  // ignore: unused_field
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserTier();
  }

  Future<void> _fetchUserTier() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_profile_info?user_id=${widget.userId}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Ambil data tier dari database (isinya 'regular', 'blue', atau 'gold')
            _userTier = data['tier'] ?? 'regular';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error check tier: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM HEADER ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _onTabTapped(0),
                    child: Image.asset(
                      _currentIndex == 0
                          ? 'assets/images/Community Active.png'
                          : 'assets/images/Community Inactive.png',
                      width: 75.w,
                      height: 75.w,
                    ),
                  ),
                  Text(
                    _currentIndex == 0 ? "Community" : "Event",
                    style: TextStyle(color: Colors.black, fontSize: 45.sp, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => _onTabTapped(1),
                    child: Image.asset(
                      _currentIndex == 1 ? 'assets/images/Event Active.png' : 'assets/images/Event Inactive.png',
                      width: 75.w,
                      height: 75.w,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // --- PAGE VIEW ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [_buildCommunityTab(), _buildEventTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: COMMUNITY ---
  Widget _buildCommunityTab() {
    // 🔥 FIX LOGIC: Cek 'blue' (Verified) atau 'gold' (Vendor)
    // Supaya aman, kita cek lowercase biar gak sensitif huruf besar/kecil
    String tier = _userTier.toLowerCase();
    bool canCreate = tier == 'blue' || tier == 'gold' || tier == 'verified' || tier == 'vendor';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Column(
        children: [
          SizedBox(height: 50.h),

          if (canCreate) _buildCreateButton("Create new community", isCommunity: true),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_outlined, size: 250.sp, color: Colors.grey.shade400),
                SizedBox(height: 40.h),
                Text(
                  "you haven't created any\ncommunity yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                SizedBox(height: 200.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: EVENT ---
  Widget _buildEventTab() {
    // 🔥 FIX LOGIC: Hanya 'gold' (Vendor) yang bisa bikin Event
    String tier = _userTier.toLowerCase();
    bool canCreate = tier == 'gold' || tier == 'vendor';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Column(
        children: [
          SizedBox(height: 50.h),

          if (canCreate) _buildCreateButton("Create new event", isCommunity: false),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_vintage_outlined, size: 250.sp, color: Colors.grey.shade400),
                SizedBox(height: 40.h),
                Text(
                  "you haven't created any\nevent yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                SizedBox(height: 200.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(String text, {required bool isCommunity}) {
    return GestureDetector(
      onTap: () {
        if (isCommunity) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddCommunityPage(userId: widget.userId)));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Fitur Create Event belum tersedia (Dummy)")));
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 50.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withOpacity(0.9),
          borderRadius: BorderRadius.circular(50.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10.r, offset: Offset(0, 5.h))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Icon(Icons.add, size: 60.sp, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
