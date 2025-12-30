import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'detail_post_page.dart';
import '../widgets/verification_badge.dart';
import '../widgets/blur_header.dart';

class VisitProfilePage extends StatefulWidget {
  final int userId;
  final String username;
  final int visitorId;

  const VisitProfilePage({super.key, required this.userId, required this.username, required this.visitorId});

  @override
  State<VisitProfilePage> createState() => _VisitProfilePageState();
}

class _VisitProfilePageState extends State<VisitProfilePage> {
  Map<String, dynamic>? _userProfile;
  List _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  late ScrollController _scrollController;
  bool _showTopBar = false;
  double _headerBlur = 0.0;

  // 🔥 1. KEMBALIKAN LOGIKA HITUNG MANUAL
  double _gridHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.offset > 400.h && !_showTopBar) {
        setState(() {
          _showTopBar = true;
          _headerBlur = 4.0;
        });
      } else if (_scrollController.offset <= 400.h && _showTopBar) {
        setState(() {
          _showTopBar = false;
          _headerBlur = 0.0;
        });
      }
    });

    _fetchProfileData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      final resInfo = await http.get(
        Uri.parse("${Config.baseUrl}/get_profile_info?user_id=${widget.userId}&visitor_id=${widget.visitorId}"),
      );
      final resPosts = await http.get(
        Uri.parse("${Config.baseUrl}/get_user_posts?user_id=${widget.userId}&visitor_id=${widget.visitorId}"),
      );

      if (resInfo.statusCode == 200 && resPosts.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(resInfo.body);
          setState(() {
            _userProfile = data;
            _userPosts = jsonDecode(resPosts.body);
            _isFollowing = data['is_following'] ?? false;
            _isLoading = false;

            // 🔥 2. HITUNG TINGGI SETELAH DATA DAPAT
            _calculateGridHeight();
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 3. RUMUS MATEMATIKA (MIRIP PROFILE PAGE)
  void _calculateGridHeight() {
    if (_userPosts.isEmpty) {
      // Kalau kosong, tingginya CUKUP segini aja (misal 500.h).
      // JANGAN 1.sh (layar penuh), nanti dia jadi bisa discroll jauh padahal kosong.
      // Dengan 500.h, dia bakal "membal" cantik karena kontennya < layar.
      _gridHeight = 500.h;
    } else {
      // Hitung tinggi berdasarkan jumlah baris
      double itemWidth = 1.sw / 3; // Lebar per item
      int rows = (_userPosts.length / 3).ceil();

      // Rumus: (Total Baris * Tinggi Item) + (Total Gap) + Extra Space Bawah
      _gridHeight = (rows * itemWidth) + (rows * 2.w) + 200.h;

      // Kalo postingan dikit (misal cuma 1 baris), kita paksa minimal 500.h
      // Supaya background putihnya gak putus mendadak.
      if (_gridHeight < 500.h) _gridHeight = 500.h;
    }
  }

  Future<void> _toggleFollow() async {
    bool oldStatus = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      if (_userProfile != null) {
        int current = _userProfile!['stats']['followers'];
        _userProfile!['stats']['followers'] = _isFollowing ? current + 1 : current - 1;
      }
    });

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_follow"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"follower_id": widget.visitorId, "followed_id": widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isFollowing = data['is_following'];
          if (_userProfile != null) {
            _userProfile!['stats']['followers'] = data['total_followers'];
          }
        });
      } else {
        setState(() => _isFollowing = oldStatus);
      }
    } catch (e) {
      setState(() => _isFollowing = oldStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    String headerUrl = _userProfile?['header_url'] ?? "";
    String avatarUrl = _userProfile?['avatar_url'] ?? "";
    String bio = _userProfile?['bio'] ?? "";
    String displayUsername = _userProfile?['username'] ?? widget.username;

    final double headerHeight = 600.h;
    final double maskingTopStart = 300.h;
    final double cardBorderRadius = 80.r;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // LAYER 1: HEADER IMAGE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: BlurHeader(
              imageUrl: headerUrl,
              height: headerHeight,
              blurStrength: _headerBlur,
              overlayOpacity: 0.3,
            ),
          ),

          // LAYER 2: BODY SCROLL
          Positioned.fill(
            top: maskingTopStart,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(cardBorderRadius),
                topRight: Radius.circular(cardBorderRadius),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: RefreshIndicator(
                  onRefresh: _fetchProfileData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      // A. GAP
                      SliverToBoxAdapter(child: SizedBox(height: headerHeight - maskingTopStart - 100.h)),

                      // B. INFO PROFILE
                      SliverToBoxAdapter(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(cardBorderRadius),
                                  topRight: Radius.circular(cardBorderRadius),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(80.w, 150.h, 80.w, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayUsername,
                                            style: TextStyle(fontSize: 70.sp, fontWeight: FontWeight.w900),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        VerificationBadge(tier: _userProfile?['tier'] ?? 'regular', size: 50.sp),
                                      ],
                                    ),
                                    if (bio.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 15.h),
                                        child: Text(
                                          bio,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 38.sp),
                                        ),
                                      ),
                                    SizedBox(height: 50.h),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            _userProfile!['stats']['posts'].toString(),
                                            "Creations",
                                          ),
                                        ),
                                        SizedBox(width: 90.w),
                                        Container(height: 100.h, width: 5.w, color: Colors.grey.shade300),
                                        SizedBox(width: 90.w),
                                        Expanded(
                                          child: _buildStatItem(
                                            _userProfile!['stats']['followers'].toString(),
                                            "Followers",
                                          ),
                                        ),
                                        SizedBox(width: 90.w),
                                        Container(height: 100.h, width: 5.w, color: Colors.grey.shade300),
                                        SizedBox(width: 90.w),
                                        Expanded(
                                          child: _buildStatItem(
                                            _userProfile!['stats']['following'].toString(),
                                            "Followings",
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 50.h),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -120.h,
                              left: 80.w,
                              child: Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: 130.r,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 70.h,
                              right: 80.w,
                              child: ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing ? Colors.white : Colors.blue,
                                  side: _isFollowing ? const BorderSide(color: Colors.grey, width: 2) : BorderSide.none,
                                  padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 20.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _isFollowing ? "Following" : "Follow",
                                  style: TextStyle(
                                    color: _isFollowing ? Colors.black : Colors.white,
                                    fontSize: 40.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // C. STICKY HEADER "CREATIONS"
                      SliverPersistentHeader(pinned: true, delegate: _CreationsHeaderDelegate()),
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          height: _gridHeight,
                          padding: EdgeInsets.zero,
                          alignment: Alignment.topCenter,
                          child: _userPosts.isEmpty
                              ? Container(
                                  height: 300.h,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Belum ada postingan",
                                    style: TextStyle(fontSize: 40.sp, color: Colors.grey),
                                  ),
                                )
                              : GridView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(), // Scroll ikut parent
                                  shrinkWrap: true,
                                  itemCount: _userPosts.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 2.w,
                                    mainAxisSpacing: 2.w,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemBuilder: (context, index) {
                                    final post = _userPosts[index];
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetailPostPage(
                                              title: "Creations",
                                              username: displayUsername,
                                              posts: _userPosts,
                                              initialIndex: index,
                                              currentUserId: widget.visitorId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl: post['image_url'],
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),

                      // Extra padding (Opsional, kalau mau ada ruang napas di bawah banget)
                      SliverToBoxAdapter(
                        child: Container(height: 720.h, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: TOP BAR STICKY
          Positioned(
            top: 60.h,
            left: 0.w,
            right: 0.w,
            height: 250.h,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.transparent,
              padding: EdgeInsets.only(top: 80.h, left: 40.w, right: 40.w),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 70.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_showTopBar) ...[
                    SizedBox(width: 0.w),
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                    ),
                    SizedBox(width: 20.w),
                    Row(
                      children: [
                        Text(
                          displayUsername,
                          style: TextStyle(fontSize: 50.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(width: 10.w),
                        VerificationBadge(tier: _userProfile?['tier'] ?? 'regular', size: 40.sp),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 64.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 35.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _CreationsHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 120.h;
  @override
  double get maxExtent => 120.h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      // Padding boleh dihapus atau dikecilkan kalau mau benar-benar center tanpa gangguan
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      alignment: Alignment.center, // Container rata tengah
      child: Row(
        // 🔥 INI KUNCINYA KING! BIAR ITEM DI DALAM ROW JADI TENGAH 🔥
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view_rounded, size: 60.sp),
          SizedBox(width: 20.w),
          Text(
            "Creations",
            style: TextStyle(fontSize: 45.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CreationsHeaderDelegate oldDelegate) => false;
}
