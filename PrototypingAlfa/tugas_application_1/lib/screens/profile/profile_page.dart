import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config.dart';
import 'edit_profile_page.dart';
import 'detail_post_page.dart';
import '../../widgets/verification_badge.dart';
import '../../widgets/blur_header.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userProfile;
  List _userPosts = [];
  List _savedPosts = [];

  bool _isLoading = true;
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTopBar = false;
  double _gridHeight = 1000.h;

  double _headerBlur = 0.0;
  double _headerOpacity = 0.0;
  // ignore: unused_field
  String _headerTitle = "Creations";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.offset > 400.h && !_showTopBar) {
        setState(() {
          _showTopBar = true;
          _headerBlur = 4.0;
          _headerOpacity = 0.4;
        });
      } else if (_scrollController.offset <= 400.h && _showTopBar) {
        setState(() {
          _showTopBar = false;
          _headerBlur = 0.0;
          _headerOpacity = 0.0;
        });
      }
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _calculateGridHeight();
          if (_tabController.index == 2) {
            _headerTitle = "Saved";
          } else {
            _headerTitle = "Creations";
          }
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

  void _calculateGridHeight() {
    List targetList = [];
    if (_tabController.index == 0) {
      targetList = _userPosts;
    } else if (_tabController.index == 2) {
      targetList = _savedPosts;
    }

    if (_tabController.index == 0 || _tabController.index == 2) {
      if (targetList.isEmpty) {
        _gridHeight = 800.h;
      } else {
        double itemSize = (1.sw - 10.w) / 3;
        int rows = (targetList.length / 3).ceil();
        _gridHeight = (rows * itemSize) + (rows * 5.h) + 500.h;
      }
    } else {
      _gridHeight = 1000.h;
    }
  }

  Future<void> _fetchProfileData() async {
    try {
      final resInfo = await http.get(
        Uri.parse("${Config.baseUrl}/get_profile_info?user_id=${widget.userId}&visitor_id=${widget.userId}"),
      );

      final resPosts = await http.get(
        Uri.parse("${Config.baseUrl}/get_user_posts?user_id=${widget.userId}&visitor_id=${widget.userId}"),
      );

      final resSaved = await http.get(
        Uri.parse("${Config.baseUrl}/get_saved_posts?user_id=${widget.userId}&visitor_id=${widget.userId}"),
      );

      if (resInfo.statusCode == 200 && resPosts.statusCode == 200) {
        if (mounted) {
          setState(() {
            _userProfile = jsonDecode(resInfo.body);
            _userPosts = jsonDecode(resPosts.body);
            if (resSaved.statusCode == 200) {
              _savedPosts = jsonDecode(resSaved.body);
            }
            _isLoading = false;
            _calculateGridHeight();
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPostTap(int index, String type) async {
    List sourceList = (type == 'saved') ? _savedPosts : _userPosts;
    List<Map<String, dynamic>> targetList = sourceList.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();

    // 🔥 UPDATE: AMBIL DISPLAY NAME
    String myName = _userProfile!['display_name'] ?? _userProfile!['username'] ?? "User";

    if (type == 'creation') {
      String myAvatar = _userProfile!['avatar_url'] ?? "";
      for (var post in targetList) {
        post['avatar_url'] ??= myAvatar;
        post['username'] ??= myName; // Gunakan Display Name
        if (post['caption'] == null) {
          post['caption'] = "";
        }
      }
    }

    String title = (type == 'saved') ? "Saved" : "Creations";

    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostPage(
          title: title,
          username: myName,
          posts: targetList,
          initialIndex: index,
          currentUserId: widget.userId,
        ),
      ),
    );

    if (shouldRefresh == true) {
      _fetchProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_userProfile == null) return const Scaffold(body: Center(child: Text("Gagal memuat profil")));

    String? headerUrl = _userProfile!['header_url'];
    String? avatarUrl = _userProfile!['avatar_url'];

    // 🔥 UPDATE UTAMA: PRIORITASKAN DISPLAY NAME
    // Jika backend mengirim 'display_name', pakai itu. Jika tidak, pakai 'username'.
    String displayName = _userProfile!['display_name'] ?? _userProfile!['username'] ?? "User";
    String rawUsername = _userProfile!['username'] ?? "User";

    String bio = _userProfile!['bio'] ?? "";

    final double headerHeight = 600.h;
    final double maskingTopStart = 300.h;
    final double cardBorderRadius = 80.r;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
              overlayOpacity: _headerOpacity,
            ),
          ),

          // LAYER 2: CONTENT SCROLL
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
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      // A. GAP HEADER
                      SliverToBoxAdapter(child: SizedBox(height: headerHeight - maskingTopStart - 100.h)),

                      // B. INFO PROFILE
                      SliverToBoxAdapter(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 0),
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
                                    // 🔥 NAMA USER (DISPLAY NAME)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName, // ✅ Pakai Display Name
                                            style: TextStyle(fontSize: 70.sp, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        VerificationBadge(tier: _userProfile!['tier'] ?? 'regular', size: 60.sp),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 0.h), // Jarak dikit dari nama
                                      child: Text(
                                        "@$rawUsername", // Pakai @ di depan
                                        style: TextStyle(
                                          fontSize: 38.sp,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // BIO
                                    if (bio.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 15.h),
                                        child: Text(
                                          bio,
                                          style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 38.sp),
                                        ),
                                      ),
                                    SizedBox(height: 50.h),

                                    // STATS
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

                            // FOTO PROFIL
                            Positioned(
                              top: -120.h,
                              left: 80.w,
                              child: Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: 130.r,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null,
                                ),
                              ),
                            ),

                            // TOMBOL EDIT
                            Positioned(
                              top: 30.h,
                              right: 50.w,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final Map<String, dynamic> dataToSend = Map.from(_userProfile!);
                                  dataToSend['id'] = widget.userId;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditProfilePage(userProfile: dataToSend, onProfileUpdated: _fetchProfileData),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.edit_outlined, color: Colors.white, size: 50.sp),
                                label: Text(
                                  "Edit Profile",
                                  style: TextStyle(color: Colors.white, fontSize: 40.sp, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // C. TAB BAR
                      SliverPersistentHeader(pinned: true, delegate: _SafeTabBarDelegate(_tabController)),

                      // D. ISI GRID
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          constraints: BoxConstraints(minHeight: 2000.h),
                          child: Column(
                            children: [
                              SizedBox(
                                height: _gridHeight,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // CREATIONS
                                    _userPosts.isEmpty
                                        ? Center(
                                            child: Text("Belum ada postingan", style: TextStyle(fontSize: 40.sp)),
                                          )
                                        : GridView.builder(
                                            padding: EdgeInsets.zero,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _userPosts.length,
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 5.w,
                                              mainAxisSpacing: 5.w,
                                              childAspectRatio: 1.0,
                                            ),
                                            itemBuilder: (context, index) {
                                              final post = _userPosts[index];
                                              return InkWell(
                                                onTap: () => _onPostTap(index, 'creation'),
                                                child: CachedNetworkImage(
                                                  imageUrl: post['image_url'],
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                                ),
                                              );
                                            },
                                          ),
                                    // LOCKED
                                    Center(
                                      child: Icon(Icons.lock_outline, size: 150.sp, color: Colors.grey.shade400),
                                    ),
                                    // SAVED
                                    _savedPosts.isEmpty
                                        ? Center(
                                            child: Text(
                                              "Belum ada yang disave",
                                              style: TextStyle(fontSize: 40.sp, color: Colors.grey),
                                            ),
                                          )
                                        : GridView.builder(
                                            padding: EdgeInsets.zero,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _savedPosts.length,
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 5.w,
                                              mainAxisSpacing: 5.w,
                                              childAspectRatio: 1.0,
                                            ),
                                            itemBuilder: (context, index) {
                                              final post = _savedPosts[index];
                                              return InkWell(
                                                onTap: () => _onPostTap(index, 'saved'),
                                                child: CachedNetworkImage(
                                                  imageUrl: post['image_url'],
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 400.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: TOP BAR
          Positioned(
            top: 150.h,
            left: 50.w,
            right: 50.w,
            height: 120.h,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showTopBar ? 1.0 : 0.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                    ),
                    SizedBox(width: 30.w),
                    // 🔥 TOP BAR NAME (DISPLAY NAME)
                    Text(
                      displayName, // ✅ Pakai Display Name
                      style: TextStyle(fontSize: 50.sp, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    SizedBox(width: 15.w),
                    VerificationBadge(tier: _userProfile?['tier'] ?? 'regular', size: 40.sp),
                  ],
                ),
              ),
            ),
          ),

          // TOMBOL KANAN ATAS
          Positioned(
            top: 180.h,
            right: 100.w,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    print("Course dipencet");
                  },
                  child: Image.asset('assets/images/Course Button.png', width: 70.w, height: 70.w),
                ),
                SizedBox(width: 50.w),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                  },
                  child: Icon(Icons.settings, size: 70.sp, color: Colors.white),
                ),
              ],
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
          style: TextStyle(fontSize: 35.sp, color: const Color.fromARGB(255, 100, 100, 100)),
        ),
      ],
    );
  }
}

class _SafeTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController _controller;
  _SafeTabBarDelegate(this._controller);
  @override
  double get minExtent => 100.h;
  @override
  double get maxExtent => 100.h;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 100.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: TabBar(
        controller: _controller,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
        indicatorWeight: 5.h,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(
            height: 150.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, size: 70.sp),
                SizedBox(height: 20.h),
              ],
            ),
          ),
          Tab(
            height: 150.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 70.sp),
                SizedBox(height: 20.h),
              ],
            ),
          ),
          Tab(
            height: 150.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border_rounded, size: 70.sp),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SafeTabBarDelegate oldDelegate) => false;
}
