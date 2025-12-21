import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'edit_profile_page.dart';
import 'detail_post_page.dart';
import 'detail_post_page.dart'; // Sesuaikan pathnya ya king

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
  double _gridHeight = 1000;

  // Header Title Dinamis
  String _headerTitle = "Creations";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showTopBar) {
        setState(() => _showTopBar = true);
      } else if (_scrollController.offset <= 400 && _showTopBar) {
        setState(() => _showTopBar = false);
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
        _gridHeight = 800;
      } else {
        double itemSize = (1080 - 10) / 3;
        int rows = (targetList.length / 3).ceil();
        _gridHeight = (rows * itemSize) + (rows * 5) + 500;
      }
    } else {
      _gridHeight = 1000;
    }
  }

  Future<void> _fetchProfileData() async {
    try {
      final resInfo = await http.get(Uri.parse("${Config.baseUrl}/get_profile_info?user_id=${widget.userId}"));
      final resPosts = await http.get(Uri.parse("${Config.baseUrl}/get_user_posts?user_id=${widget.userId}"));
      final resSaved = await http.get(Uri.parse("${Config.baseUrl}/get_saved_posts?user_id=${widget.userId}"));

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

    // 1. Cloning & Injection Data
    List<Map<String, dynamic>> targetList = sourceList.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();

    if (type == 'creation') {
      String myAvatar = _userProfile!['avatar_url'] ?? "";
      String myName = _userProfile!['username'] ?? "User";

      for (var post in targetList) {
        post['avatar_url'] ??= myAvatar;
        post['username'] ??= myName;
        // 🔥 JAGA-JAGA: Kalau caption null, kasih string kosong
        // Tapi JANGAN di-overwrite kalau API udah ngasih caption
        if (post['caption'] == null) {
          post['caption'] = "";
        }
      }
    }

    String title = (type == 'saved') ? "Saved" : "Creations";
    String headerUsername = _userProfile!['username'] ?? "User";

    // 2. Navigasi dengan Data LENGKAP
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostPage(
          title: title,
          username: headerUsername,
          posts: targetList,
          initialIndex: index,
          currentUserId: widget.userId, // 🔥 KIRIM ID DISINI KING
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
    String username = _userProfile!['username'] ?? "User";
    String bio = _userProfile!['bio'] ?? "";

    const double headerHeight = 600.0;
    const double maskingTopStart = 300.0;
    const double cardBorderRadius = 80.0;

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
            child: (headerUrl != null && headerUrl.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: headerUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade300),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
                  )
                : Container(color: Colors.grey.shade300),
          ),

          // LAYER 2: CONTENT SCROLL
          Positioned.fill(
            top: maskingTopStart,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
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
                      const SliverToBoxAdapter(child: SizedBox(height: headerHeight - maskingTopStart - 100)),

                      // B. INFO PROFILE
                      SliverToBoxAdapter(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 0),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(cardBorderRadius),
                                  topRight: Radius.circular(cardBorderRadius),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(80, 150, 80, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(username, style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900)),
                                    if (bio.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 15),
                                        child: Text(bio, style: TextStyle(color: Colors.grey.shade700, fontSize: 38)),
                                      ),
                                    const SizedBox(height: 60),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildStatItem(
                                          _tabController.index == 2
                                              ? _savedPosts.length.toString()
                                              : _userProfile!['stats']['posts'].toString(),
                                          _headerTitle,
                                        ),
                                        const SizedBox(width: 105),
                                        Container(height: 100, width: 5, color: Colors.grey.shade300),
                                        const SizedBox(width: 105),
                                        _buildStatItem(_userProfile!['stats']['followers'].toString(), "Followers"),
                                        const SizedBox(width: 105),
                                        Container(height: 100, width: 5, color: Colors.grey.shade300),
                                        const SizedBox(width: 105),
                                        _buildStatItem(_userProfile!['stats']['following'].toString(), "Followings"),
                                      ],
                                    ),
                                    const SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -120,
                              left: 80,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: 130,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 70,
                              right: 80,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfilePage(
                                        userId: widget.userId,
                                        currentUsername: username,
                                        currentBio: bio,
                                        currentAvatarUrl: avatarUrl ?? "",
                                        currentHeaderUrl: headerUrl ?? "",
                                      ),
                                    ),
                                  );
                                  if (result == true) _fetchProfileData();
                                },
                                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 50),
                                label: const Text(
                                  "Edit Profile",
                                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // C. TOMBOL TAB
                      SliverPersistentHeader(pinned: true, delegate: _SafeTabBarDelegate(_tabController)),

                      // D. ISI POSTINGAN (GRID CLICKABLE)
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          constraints: const BoxConstraints(minHeight: 2000),
                          child: Column(
                            children: [
                              SizedBox(
                                height: _gridHeight,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // TAB 1 (CREATIONS)
                                    _userPosts.isEmpty
                                        ? const Center(
                                            child: Text("Belum ada postingan", style: TextStyle(fontSize: 40)),
                                          )
                                        : GridView.builder(
                                            padding: EdgeInsets.zero,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _userPosts.length,
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 5,
                                              mainAxisSpacing: 5,
                                              childAspectRatio: 1.0,
                                            ),
                                            itemBuilder: (context, index) {
                                              final post = _userPosts[index];
                                              return InkWell(
                                                onTap: () => _onPostTap(index, 'creation'), // Kirim index + tipe
                                                child: CachedNetworkImage(
                                                  // ... codingan image sama kayak sebelumnya
                                                  imageUrl: post['image_url'],
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                                ),
                                              );
                                            },
                                          ),

                                    // TAB 2 (LOCKED)
                                    Center(child: Icon(Icons.lock_outline, size: 150, color: Colors.grey.shade400)),

                                    // TAB 3 (SAVED)
                                    _savedPosts.isEmpty
                                        ? const Center(
                                            child: Text(
                                              "Belum ada yang disave",
                                              style: TextStyle(fontSize: 40, color: Colors.grey),
                                            ),
                                          )
                                        : GridView.builder(
                                            padding: EdgeInsets.zero,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _savedPosts.length,
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 5,
                                              mainAxisSpacing: 5,
                                              childAspectRatio: 1.0,
                                            ),
                                            itemBuilder: (context, index) {
                                              final post = _savedPosts[index];
                                              return InkWell(
                                                onTap: () => _onPostTap(index, 'saved'), // Kirim index + tipe
                                                child: CachedNetworkImage(
                                                  // ... codingan image sama kayak sebelumnya
                                                  imageUrl: post['image_url'],
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 400),
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

          // LAYER 3: TOP BAR STICKY
          Positioned(
            top: 150,
            left: 50,
            right: 50,
            height: 120,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showTopBar ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                color: Colors.white.withOpacity(0),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                    ),
                    const SizedBox(width: 30),
                    Text(
                      _headerTitle,
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
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
        Text(count, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 35, color: Color.fromARGB(255, 100, 100, 100))),
      ],
    );
  }
}

// 🔒 DELEGATE LOCKED 🔒
class _SafeTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController _controller;

  _SafeTabBarDelegate(this._controller);
  @override
  double get minExtent => 100.0;
  @override
  double get maxExtent => 100.0;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      height: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: TabBar(
        controller: _controller,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
        indicatorWeight: 5,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Icon(Icons.grid_view_rounded, size: 70), SizedBox(height: 20)],
            ),
          ),
          Tab(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Icon(Icons.lock_outline_rounded, size: 70), SizedBox(height: 20)],
            ),
          ),
          Tab(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Icon(Icons.bookmark_border_rounded, size: 70), SizedBox(height: 20)],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SafeTabBarDelegate oldDelegate) => false;
}

// -------------------------------------------------------------------------
// 👇 INI WIDGET BARU BUAT VISIT / DETAIL PAGE (PLACEHOLDER) 👇
// Nanti King bisa isi codingan UI detailnya di dalam sini
// -------------------------------------------------------------------------

class CreationDetailView extends StatelessWidget {
  final Map<String, dynamic> postData;
  const CreationDetailView({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Creation Detail")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Ini Halaman Detail CREATION", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            // Contoh nampilin gambar yang diklik
            CachedNetworkImage(imageUrl: postData['image_url'], height: 300),
          ],
        ),
      ),
    );
  }
}

class SavedDetailView extends StatelessWidget {
  final Map<String, dynamic> postData;
  const SavedDetailView({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Post Detail")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Ini Halaman Detail SAVED", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            // Contoh nampilin gambar yang diklik
            CachedNetworkImage(imageUrl: postData['image_url'], height: 300),
          ],
        ),
      ),
    );
  }
}
