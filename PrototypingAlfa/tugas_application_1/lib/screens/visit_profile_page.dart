import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'detail_post_page.dart';
import '../widgets/verification_badge.dart'; // <--- JANGAN LUPA INI

class VisitProfilePage extends StatefulWidget {
  final int userId; // ID Orang yang dikunjungi
  final String username; // Nama Orang
  final int visitorId; // ID Kita

  const VisitProfilePage({
    super.key,
    required this.userId,
    required this.username,
    required this.visitorId, // Wajib ada
  });

  @override
  State<VisitProfilePage> createState() => _VisitProfilePageState();
}

class _VisitProfilePageState extends State<VisitProfilePage> {
  Map<String, dynamic>? _userProfile;
  List _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false; // Status Follow

  late ScrollController _scrollController;
  bool _showTopBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 400.h && !_showTopBar) {
        setState(() => _showTopBar = true);
      } else if (_scrollController.offset <= 400.h && _showTopBar) {
        setState(() => _showTopBar = false);
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
      // 🔥 KIRIM JUGA visitor_id BIAR TAU STATUS FOLLOW
      final resInfo = await http.get(
        Uri.parse("${Config.baseUrl}/get_profile_info?user_id=${widget.userId}&visitor_id=${widget.visitorId}"),
      );
      final resPosts = await http.get(Uri.parse("${Config.baseUrl}/get_user_posts?user_id=${widget.userId}"));

      if (resInfo.statusCode == 200 && resPosts.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(resInfo.body);
          setState(() {
            _userProfile = data;
            _userPosts = jsonDecode(resPosts.body);
            _isFollowing = data['is_following'] ?? false; // Ambil status dari server
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI TOMBOL FOLLOW ---
  Future<void> _toggleFollow() async {
    // Optimistic UI (Ubah dulu biar cepet)
    setState(() {
      _isFollowing = !_isFollowing;
      // Update angka followers sementara
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

      if (response.statusCode != 200) {
        // Kalau gagal, balikin statusnya
        setState(() => _isFollowing = !_isFollowing);
      }
    } catch (e) {
      print("Error Follow: $e");
      setState(() => _isFollowing = !_isFollowing);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Safety check kalau data null
    String headerUrl = _userProfile?['header_url'] ?? "";
    String avatarUrl = _userProfile?['avatar_url'] ?? "";
    String bio = _userProfile?['bio'] ?? "";

    // Kalau username dari server kosong, pakai yang dari widget
    String displayUsername = _userProfile?['username'] ?? widget.username;

    // Constants
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
            child: headerUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: headerUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade300),
                  )
                : Container(color: Colors.grey.shade300),
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
                                    // NAMA
                                    // NAMA
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
                                        // 🔥 PASANG BADGE DI SINI
                                        VerificationBadge(tier: _userProfile?['tier'] ?? 'regular', size: 50.sp),
                                      ],
                                    ),
                                    // BIO
                                    if (bio.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 15.h),
                                        child: Text(
                                          bio,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 38.sp),
                                        ),
                                      ),
                                    SizedBox(height: 50.h),

                                    // STATS (Sama kayak profile sendiri)
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

                            // AVATAR
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

                            // 🔥 TOMBOL FOLLOW (GANTINYA EDIT PROFILE) 🔥
                            Positioned(
                              top: 70.h,
                              right: 80.w,
                              child: ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  // Kalau Following: Putih border Hitam, Kalau Follow: Biru
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

                      // C. JUDUL "Creations" (Pengganti TabBar)
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 30.h),
                          child: Row(
                            children: [
                              Icon(Icons.grid_view_rounded, size: 60.sp),
                              SizedBox(width: 20.w),
                              Text(
                                "Creations",
                                style: TextStyle(fontSize: 45.sp, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // D. GRID POSTINGAN (Langsung Grid, tanpa TabBarView)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w), // Biar ada jarak dikit
                        sliver: _userPosts.isEmpty
                            ? SliverToBoxAdapter(
                                child: Container(
                                  height: 500.h,
                                  color: Colors.white,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Belum ada postingan",
                                    style: TextStyle(fontSize: 40.sp, color: Colors.grey),
                                  ),
                                ),
                              )
                            : SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 5.w,
                                  mainAxisSpacing: 5.w,
                                  childAspectRatio: 1.0,
                                ),
                                delegate: SliverChildBuilderDelegate((context, index) {
                                  final post = _userPosts[index];
                                  return InkWell(
                                    onTap: () {
                                      // Ke Detail Page
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailPostPage(
                                            title: "Creations",
                                            username: displayUsername,
                                            posts: _userPosts, // Cuma kirim creations
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
                                }, childCount: _userPosts.length),
                              ),
                      ),

                      // Padding Bawah
                      SliverToBoxAdapter(
                        child: Container(height: 200.h, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: TOP BAR STICKY (BACK + AVATAR + NAME)
          Positioned(
            top: 60.h,
            left: 0.w,
            right: 0.w,
            height: 250.h,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              // Kalau discroll ke bawah, kasih background putih + shadow
              color: _showTopBar ? const Color.fromARGB(0, 255, 255, 255) : Colors.transparent,
              padding: EdgeInsets.only(top: 80.h, left: 40.w, right: 40.w),
              child: Row(
                children: [
                  // TOMBOL BACK
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: _showTopBar ? const Color.fromARGB(255, 0, 0, 0) : Colors.white,
                      size: 70.sp,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // INFO (MUNCUL PAS SCROLL)
                  if (_showTopBar) ...[
                    SizedBox(width: 0.w),
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                      backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                    ),
                    SizedBox(width: 20.w),
                    Row(
                      children: [
                        Text(
                          displayUsername,
                          style: TextStyle(fontSize: 50.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10.w),
                        // 🔥 PASANG BADGE VERSI KECIL
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
