import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config.dart';
import '../../../widgets/verification_badge.dart';
import 'menu_community.dart';
import '../../home/notification_detail_post_page.dart';
import 'community_approval_page.dart';
import '../../../widgets/unite_item.dart';
import 'create_unite_page.dart';

class CommunityProfilePage extends StatefulWidget {
  final int communityId;
  final int currentUserId;

  const CommunityProfilePage({super.key, required this.communityId, required this.currentUserId});

  @override
  State<CommunityProfilePage> createState() => _CommunityProfilePageState();
}

class _CommunityProfilePageState extends State<CommunityProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  Map<String, dynamic>? _communityData;
  List _chatMessages = [];
  List _taggedPosts = [];
  bool _isLoading = true;
  bool _isSticky = false;
  bool _isJoined = false;
  bool _isJoinLoading = false;

  double _listHeight = 1000.h;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.offset > 350.h && !_isSticky) {
        setState(() => _isSticky = true);
      } else if (_scrollController.offset <= 350.h && _isSticky) {
        setState(() => _isSticky = false);
      }
    });

    // Listener untuk update tinggi saat ganti tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _calculateListHeight();
        });
      }
    });

    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchCommunityData();
    await _fetchMessages();
    await _fetchTaggedPosts();
    if (mounted) setState(() => _calculateListHeight());
  }

  void _calculateListHeight() {
    double minHeight = 0.747.sh; // Magic Number King
    double calculatedHeight = 0;

    if (_tabController.index == 0) {
      if (_taggedPosts.isEmpty) {
        calculatedHeight = 0;
      } else {
        double itemSize = (1.sw) / 3;
        int rows = (_taggedPosts.length / 3).ceil();
        calculatedHeight = (rows * itemSize) + 300.h;
      }
    } else {
      if (!_isJoined || _chatMessages.isEmpty) {
        calculatedHeight = 0;
      } else {
        double totalChatHeight = 0;
        for (var msg in _chatMessages) {
          String content = msg['content'] ?? "";
          double baseItemHeight = 180.h;
          double textLines = (content.length / 40).ceilToDouble();
          if (textLines < 1) textLines = 1;
          double textHeight = textLines * 40.h;
          totalChatHeight += (baseItemHeight + textHeight);
        }
        calculatedHeight = totalChatHeight + 200.h;
      }
    }
    _listHeight = (calculatedHeight > minHeight) ? calculatedHeight : minHeight;
  }

  Future<void> _fetchTaggedPosts() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/get_community_tagged_posts?community_id=${widget.communityId}"),
      );
      if (response.statusCode == 200) {
        if (mounted) setState(() => _taggedPosts = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error tagged: $e");
    }
  }

  Future<void> _fetchCommunityData() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Config.baseUrl}/get_community_detail?community_id=${widget.communityId}&user_id=${widget.currentUserId}",
        ),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          final data = jsonDecode(response.body);
          setState(() {
            _communityData = data;
            _isJoined = data['is_joined'] ?? false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/get_community_messages?community_id=${widget.communityId}"),
      );
      if (response.statusCode == 200) {
        if (mounted) setState(() => _chatMessages = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error messages: $e");
    }
  }

  Future<void> _toggleJoin() async {
    setState(() => _isJoinLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_join_community"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"community_id": widget.communityId, "user_id": widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _isJoined = !_isJoined;
          if (_communityData != null && _communityData!['stats'] != null) {
            int current = _communityData!['stats']['members'];
            _communityData!['stats']['members'] = _isJoined ? current + 1 : current - 1;
          }
        });
        if (_isJoined) {
          await _fetchMessages();
          _calculateListHeight();
        }
      }
    } catch (e) {
      print("Error join: $e");
    } finally {
      setState(() => _isJoinLoading = false);
    }
  }

  Future<void> _deleteUniteMessage(int messageId) async {
    try {
      setState(() => _chatMessages.removeWhere((msg) => msg['id'] == messageId));
      _calculateListHeight();
      await http.post(
        Uri.parse("${Config.baseUrl}/delete_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message_id": messageId, "user_id": widget.currentUserId}),
      );
    } catch (e) {
      _fetchMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final data = _communityData ?? {};
    bool isOwner = (data['owner_id'] ?? -1) == widget.currentUserId;
    final double headerImageHeight = 600.h;
    final double iconSize = 250.r;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerImageHeight,
            child: (data['header_url'] != null && data['header_url'] != "")
                ? CachedNetworkImage(imageUrl: data['header_url'], fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. MONOLITHIC SCROLL VIEW
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // A. STICKY APP BAR
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                toolbarHeight: 180.h,
                backgroundColor: _isSticky ? const Color.fromARGB(255, 255, 255, 255) : Colors.transparent,
                elevation: _isSticky ? 2 : 0,
                systemOverlayStyle: _isSticky ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
                leadingWidth: 200.w,
                leading: Padding(
                  // 1. GESER TOMBOL DARI PINGGIR LAYAR (Outer Padding)
                  // Naikkan dari 40.w ke 50.w biar agak masuk
                  padding: EdgeInsets.only(left: 50.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: _isSticky ? Colors.transparent : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: _isSticky
                              ? []
                              : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        // 2. GESER ICON DI DALAM LINGKARAN (Inner Padding)
                        // Naikkan dari 24.w ke 35.w biar icon-nya pas di tengah visual
                        padding: EdgeInsets.only(left: 20.w),
                        alignment: Alignment.center,
                        child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 55.sp),
                      ),
                    ),
                  ),
                ),
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSticky ? 1.0 : 0.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Community",
                        style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data['name'] ?? "",
                        style: TextStyle(color: Colors.grey, fontSize: 40.sp, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                actions: [
                  if (isOwner)
                    Padding(
                      padding: EdgeInsets.only(right: 40.w),
                      child: Center(
                        child: Container(
                          height: 90.w,
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          decoration: BoxDecoration(
                            color: _isSticky ? Colors.transparent : Colors.white,
                            borderRadius: BorderRadius.circular(50.r),
                            boxShadow: _isSticky
                                ? []
                                : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityApprovalPage(
                                      communityId: widget.communityId,
                                      currentUserId: widget.currentUserId,
                                    ),
                                  ),
                                ),
                                child: Icon(Icons.fact_check_outlined, color: Colors.black, size: 60.sp),
                              ),
                              SizedBox(width: 40.w),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuCommunityPage(
                                        communityData: _communityData ?? {},
                                        currentUserId: widget.currentUserId,
                                      ),
                                    ),
                                  );
                                  if (result == true) _fetchCommunityData();
                                },
                                child: Icon(Icons.menu_sharp, color: Colors.black, size: 60.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // B. SPACER & INFO
              SliverToBoxAdapter(child: SizedBox(height: 450.h - 250.h)),
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(80.r)),
                      ),
                      padding: EdgeInsets.fromLTRB(70.w, (iconSize / 2) + 80.h, 70.w, 40.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? "No Name",
                            style: TextStyle(fontSize: 65.sp, fontWeight: FontWeight.w900, height: 1.1),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 35.sp, color: Colors.grey),
                              SizedBox(width: 10.w),
                              Text(
                                data['location'] ?? "",
                                style: TextStyle(
                                  fontSize: 35.sp,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 15.w),
                              Expanded(
                                child: Text(
                                  data['subtitle'] ?? "",
                                  style: TextStyle(
                                    fontSize: 35.sp,
                                    color: const Color.fromARGB(255, 7, 7, 7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          Text(
                            data['description'] ?? "",
                            style: TextStyle(fontSize: 40.sp, height: 1.5, color: Colors.black87),
                          ),
                          SizedBox(height: 40.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isJoinLoading ? null : _toggleJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isJoined ? Colors.grey.shade200 : Colors.blue,
                                foregroundColor: _isJoined ? Colors.black54 : Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 25.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                                elevation: _isJoined ? 0 : 3,
                              ),
                              child: _isJoinLoading
                                  ? SizedBox(
                                      height: 40.h,
                                      width: 40.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: _isJoined ? Colors.black : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isJoined ? "Leave Community" : "Join Community",
                                      style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          SizedBox(height: 50.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatsItem("Tagged Post", "${_taggedPosts.length}"),
                              Container(height: 100.h, width: 3.w, color: Colors.black),
                              _buildStatsItem("Members", (data['stats']?['members'] ?? 0).toString()),
                              Container(height: 100.h, width: 3.w, color: Colors.black),
                              _buildStatsItem("Total Event", (data['stats']?['events'] ?? 0).toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -(iconSize / 2),
                      left: 50.w,
                      child: Container(
                        padding: EdgeInsets.all(25.r),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: iconSize / 2,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (data['icon_url'] != null && data['icon_url'] != "")
                              ? CachedNetworkImageProvider(data['icon_url'])
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60.h,
                      right: 60.w,
                      child: Row(
                        children: [
                          if (data['creator_tier'] == 'gold' || data['creator_tier'] == 'vendor') _buildVendorBadge(),
                          if (data['creator_tier'] == 'blue' || data['creator_tier'] == 'verified')
                            VerificationBadge(tier: 'verified', size: 45.sp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // C. TAB BAR STICKY
              SliverPersistentHeader(
                pinned: true,
                delegate: _CommunityTabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: const BoxDecoration(color: Colors.blue),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color.fromARGB(255, 90, 90, 90),
                    labelStyle: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold),
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: "Tagged"),
                      Tab(text: "Unite"),
                    ],
                  ),
                ),
              ),

              // D. CONTENT BODY (MONOLITHIC)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: SizedBox(
                    height: _listHeight,
                    child: TabBarView(controller: _tabController, children: [_buildTaggedTab(), _buildUniteTab()]),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 200.h)),
            ],
          ),

          // 🔥 3. TOMBOL CREATE UNITE (FLOATING GHOST - ANIMATED)
          if (_isJoined)
            Positioned(
              // ✅ Positioned WAJIB jadi bapak paling luar di dalam Stack
              bottom: 100.h,
              right: 60.w,
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, child) {
                  // Logic: Index 1 (Unite) -> Value 1.0 -> Offset 0
                  // Index 0 (Tagged) -> Value 0.0 -> Offset Geser Kanan
                  double value = _tabController.animation!.value;
                  double translateX = (1.0 - value) * 200.w; // Geser 200 pixel ke kanan kalau bukan tab Unite

                  // Optimasi: Kalau sudah kegeser jauh, hide aja biar gak bisa diklik
                  if (translateX > 100.w) return const SizedBox();

                  return Transform.translate(offset: Offset(translateX, 0), child: child);
                },
                child: FloatingActionButton(
                  heroTag: "btn_unite",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateUnitePage(communityId: widget.communityId, currentUserId: widget.currentUserId),
                      ),
                    );
                    if (result == true) {
                      await _fetchMessages();
                      Future.delayed(const Duration(milliseconds: 500), () => _calculateListHeight());
                    }
                  },
                  backgroundColor: Colors.blue,
                  elevation: 4,
                  child: Icon(Icons.add, color: Colors.white, size: 50.sp),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildStatsItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 80.sp, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 35.sp, color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVendorBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(50.r)),
      child: Row(
        children: [
          Text(
            "Vendor",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 50.sp),
          ),
          SizedBox(width: 5.w),
          Icon(Icons.verified, color: Colors.white, size: 50.sp),
        ],
      ),
    );
  }

  Widget _buildTaggedTab() {
    if (_taggedPosts.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 100.h),
            Icon(Icons.image_not_supported_outlined, size: 200.sp, color: Colors.grey.shade300),
            SizedBox(height: 30.h),
            Text(
              "No posts yet",
              style: TextStyle(fontSize: 36.sp, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _taggedPosts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5.w,
        mainAxisSpacing: 5.w,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final post = _taggedPosts[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationDetailPostPage(postId: post['id'], currentUserId: widget.currentUserId),
            ),
          ),
          child: CachedNetworkImage(
            imageUrl: post['image_url'],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
          ),
        );
      },
    );
  }

  Widget _buildUniteTab() {
    if (!_isJoined) {
      return Center(
        child: Text(
          "Join to view discussions",
          style: TextStyle(fontSize: 36.sp, color: Colors.grey),
        ),
      );
    }
    return _chatMessages.isEmpty
        ? Center(
            child: Text(
              "No discussions yet",
              style: TextStyle(fontSize: 34.sp, color: Colors.grey),
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              return UniteItem(
                message: _chatMessages[index],
                currentUserId: widget.currentUserId,
                communityOwnerId: _communityData?['owner_id'] ?? 0,
                onDelete: _deleteUniteMessage,
              );
            },
          );
  }
}

class _CommunityTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _CommunityTabBarDelegate({required this.tabBar});
  @override
  double get minExtent => 90.h;
  @override
  double get maxExtent => 90.h;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 216, 216, 216),
        boxShadow: shrinkOffset > 0
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
            : [],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_CommunityTabBarDelegate oldDelegate) => false;
}
