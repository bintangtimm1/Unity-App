import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart'; // Jangan lupa import ini
import '../config.dart';
import 'add_community_page.dart';
import 'community_profile_page.dart'; // 🔥 IMPORT HALAMAN PROFIL

class CommunityPage extends StatefulWidget {
  final int userId;
  const CommunityPage({super.key, required this.userId});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _userTier = 'regular';

  // 🔥 DATA KOMUNITAS
  List _communities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserTier();
    _fetchCommunities(); // 🔥 AMBIL DATA SAAT MASUK
  }

  // AMBIL DATA TIER
  Future<void> _fetchUserTier() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_profile_info?user_id=${widget.userId}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _userTier = data['tier'] ?? 'regular');
      }
    } catch (e) {
      print("Error check tier: $e");
    }
  }

  // 🔥 AMBIL DATA KOMUNITAS DARI SERVER
  // 🔥 AMBIL DATA KOMUNITAS DARI SERVER
  Future<void> _fetchCommunities() async {
    try {
      // 🔥 UPDATE: Kirim parameter user_id biar backend tau siapa yg minta
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_communities?user_id=${widget.userId}"));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _communities = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetch communities: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

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
            // --- HEADER ---
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

            // --- CONTENT ---
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
    String tier = _userTier.toLowerCase();
    bool canCreate = tier == 'blue' || tier == 'gold' || tier == 'verified' || tier == 'vendor';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Column(
        children: [
          SizedBox(height: 50.h),

          if (canCreate) _buildCreateButton("Create new community", isCommunity: true),

          SizedBox(height: 50.h),

          // 🔥 LOGIC TAMPILAN: LIST VS EMPTY STATE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _communities.isEmpty
                ? _buildEmptyState("you haven't created any\ncommunity yet", Icons.layers_outlined)
                : _buildCommunityList(), // TAMPILKAN LIST JIKA ADA DATA
          ),
        ],
      ),
    );
  }

  // --- TAB 2: EVENT ---
  Widget _buildEventTab() {
    String tier = _userTier.toLowerCase();
    bool canCreate = tier == 'gold' || tier == 'vendor';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Column(
        children: [
          SizedBox(height: 50.h),
          if (canCreate) _buildCreateButton("Create new event", isCommunity: false),

          // Event masih dummy empty state dulu
          Expanded(child: _buildEmptyState("you haven't created any\nevent yet", Icons.filter_vintage_outlined)),
        ],
      ),
    );
  }

  // 🔥 WIDGET LIST COMMUNITY (UI SEMENTARA)
  Widget _buildCommunityList() {
    return ListView.separated(
      itemCount: _communities.length,
      separatorBuilder: (_, __) => SizedBox(height: 30.h),
      itemBuilder: (context, index) {
        final comm = _communities[index];
        return GestureDetector(
          onTap: () {
            // 🔥 NAVIGASI KE PROFILE COMMUNITY REAL
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityProfilePage(communityId: comm['id'], currentUserId: widget.userId),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                // ICON KOMUNITAS
                CircleAvatar(
                  radius: 60.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (comm['icon_url'] != null && comm['icon_url'] != "")
                      ? CachedNetworkImageProvider(comm['icon_url'])
                      : null,
                  child: (comm['icon_url'] == null || comm['icon_url'] == "")
                      ? Icon(Icons.groups, color: Colors.grey)
                      : null,
                ),
                SizedBox(width: 30.w),

                // NAMA KOMUNITAS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comm['name'] ?? "No Name",
                        style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${comm['member_count'] ?? 0} Members",
                        style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 50.sp, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  // WIDGET EMPTY STATE
  Widget _buildEmptyState(String text, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 250.sp, color: Colors.grey.shade400),
        SizedBox(height: 40.h),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        SizedBox(height: 200.h),
      ],
    );
  }

  Widget _buildCreateButton(String text, {required bool isCommunity}) {
    return GestureDetector(
      onTap: () async {
        if (isCommunity) {
          // 🔥 Refresh list setelah balik dari create page
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCommunityPage(userId: widget.userId)),
          );
          _fetchCommunities();
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
