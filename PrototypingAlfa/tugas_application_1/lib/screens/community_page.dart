import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';
import 'add_community_page.dart';
import 'community_profile_page.dart';
import 'add_event_page.dart';
import '../widgets/user_event_card.dart';
import 'user_event_detail_page.dart';

import '../widgets/owner_event_card.dart';
import 'owner_event_detail_page.dart';

class CommunityPage extends StatefulWidget {
  final int userId;
  const CommunityPage({super.key, required this.userId});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

// 🔥 TAMBAHKAN SingleTickerProviderStateMixin UNTUK ANIMASI
class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _userTier = 'regular';

  // DATA KOMUNITAS
  List _communities = [];
  bool _isLoading = true;

  // DATA EVENT
  List _myEvents = [];
  bool _isLoadingEvents = true;

  // 🔥 STATE BARU: MODE JOINED VS ALL
  bool _isJoinedMode = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // 🔥 INIT ANIMATION CONTROLLER
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200), // Durasi putar 0.5 detik
      vsync: this,
    );

    _fetchUserTier();
    _fetchCommunities();
    _fetchMyEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose(); // Jangan lupa dispose
    super.dispose();
  }

  // --- API FUNCTIONS ---

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

  Future<void> _fetchCommunities() async {
    try {
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

  // 3. FETCH EVENT DENGAN LOGIC TOMBOL BARU
  Future<void> _fetchMyEvents() async {
    if (_userTier == '') await _fetchUserTier();

    // 🔥 PENTING: Kosongkan list dulu biar UI bersih & loading muncul
    setState(() {
      _isLoadingEvents = true;
      _myEvents = [];
    });

    String endpoint = "";
    String tier = _userTier.toLowerCase();
    bool isOwner = tier == 'vendor' || tier == 'gold';

    if (isOwner) {
      endpoint = "/get_vendor_events";
    } else {
      // USER BIASA: Cek status tombol
      if (_isJoinedMode) {
        endpoint = "/get_user_joined_events"; // Mode JOINED
      } else {
        endpoint = "/get_all_upcoming_events"; // Mode ALL (EVENT)
      }
    }

    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}$endpoint?user_id=${widget.userId}"));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _myEvents = jsonDecode(response.body);
            _isLoadingEvents = false;
          });
        }
      } else {
        // Kalau error/404, pastikan loading mati dan list tetap kosong
        if (mounted) setState(() => _isLoadingEvents = false);
      }
    } catch (e) {
      print("Error fetch events: $e");
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }
  // --- NAVIGATION LOGIC ---

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _onTabTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // 🔥 LOGIC TOMBOL TOGGLE DI PENCET
  void _toggleEventMode() {
    // Jalankan animasi putar
    _animController.forward(from: 0.0);

    setState(() {
      _isJoinedMode = !_isJoinedMode; // Balik status
    });

    _fetchMyEvents(); // Refresh data sesuai mode baru
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // 🔥 TENTUKAN JUDUL HEADER
    String headerTitle = "Community"; // Default Tab 0
    if (_currentIndex == 1) {
      // Kalau di Tab Event, cek mode tombol
      headerTitle = _isJoinedMode ? "Joined" : "Event";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          // 🔥 PAKAI STACK UTAMA BIAR TOMBOL BISA MELAYANG DI ATAS SEGALA HAL
          children: [
            Column(
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

                      // 🔥 JUDUL BERUBAH DINAMIS
                      Text(
                        headerTitle,
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

                // --- CONTENT PAGEVIEW ---
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [_buildCommunityTab(), _buildEventTab()],
                  ),
                ),
              ],
            ),

            // 🔥 TOMBOL CUSTOM (HANYA MUNCUL DI TAB EVENT & BUKAN VENDOR)
            if (_currentIndex == 1 && !['vendor', 'gold'].contains(_userTier.toLowerCase()))
              Positioned(
                bottom: 250.h, // Posisi dari bawah (sesuaikan nanti King)
                left: 310,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleEventMode,
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(_animController), // Animasi Putar
                      child: Image.asset(
                        _isJoinedMode
                            ? 'assets/images/My event Active.png' // Gambar saat mode Joined
                            : 'assets/images/My event Non active.png', // Gambar saat mode All Event
                        width: 130.w, // Sesuaikan ukuran
                        height: 130.h, // Sesuaikan ukuran
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: COMMUNITY UI
  // ==========================================
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _communities.isEmpty
                ? _buildEmptyState("you haven't created any\ncommunity yet", Icons.layers_outlined)
                : _buildCommunityList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: EVENT UI
  // ==========================================
  Widget _buildEventTab() {
    String tier = _userTier.toLowerCase();
    bool isOwner = tier == 'gold' || tier == 'vendor';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Column(
        children: [
          SizedBox(height: 5.h),

          // TOMBOL CREATE (Hanya muncul untuk Vendor/Gold)
          if (isOwner) _buildCreateButton("Create new event", isCommunity: false),

          SizedBox(height: 50.h),

          Expanded(
            child: _isLoadingEvents
                ? const Center(child: CircularProgressIndicator())
                : _myEvents.isEmpty
                ? _buildEmptyState(
                    isOwner
                        ? "You haven't created any\nevent yet"
                        : (_isJoinedMode ? "You haven't joined any event yet" : "No upcoming events available"),
                    Icons.event_busy,
                  )
                : ListView.separated(
                    // Tambahkan padding bawah biar list paling bawah gak ketutup tombol melayang
                    padding: EdgeInsets.only(bottom: 200.h),
                    itemCount: _myEvents.length,
                    separatorBuilder: (_, __) => SizedBox(height: 30.h),
                    itemBuilder: (context, index) {
                      final event = _myEvents[index];

                      if (isOwner) {
                        return OwnerEventCard(
                          title: event['title'],
                          location: event['location'],
                          communityIconUrl: event['community_icon'],
                          eventImageUrl: event['image_url'],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OwnerEventDetailPage(eventData: event, currentUserId: widget.userId),
                              ),
                            );
                            _fetchMyEvents();
                          },
                        );
                      } else {
                        return UserEventCard(
                          title: event['title'],
                          startDate: event['start_time'],
                          endDate: event['end_time'],
                          posterUrl: event['image_url'],
                          communityIconUrl: event['community_icon'],
                          onTapDetail: () {
                            // Navigasi ke Detail User
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserEventDetailPage(
                                  eventData: event,
                                  currentUserId: widget.userId, // 🔥 WAJIB DITAMBAH DI SINI
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET HELPERS
  // ==========================================
  Widget _buildCreateButton(String text, {required bool isCommunity}) {
    return GestureDetector(
      onTap: () async {
        if (isCommunity) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCommunityPage(userId: widget.userId)),
          );
          _fetchCommunities();
        } else {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEventPage(userId: widget.userId)));
          _fetchMyEvents();
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

  Widget _buildCommunityList() {
    return ListView.separated(
      itemCount: _communities.length,
      separatorBuilder: (_, __) => SizedBox(height: 30.h),
      itemBuilder: (context, index) {
        final comm = _communities[index];
        return GestureDetector(
          onTap: () {
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
}
