import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import '../widgets/verification_badge.dart';

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
  bool _isLoading = true;
  bool _isSticky = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    // Logika Sticky Header Adaptive
    _scrollController.addListener(() {
      if (_scrollController.offset > 350.h && !_isSticky) {
        setState(() => _isSticky = true);
      } else if (_scrollController.offset <= 350.h && _isSticky) {
        setState(() => _isSticky = false);
      }
    });

    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchCommunityData();
    await _fetchMessages();
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
          setState(() {
            _communityData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching community: $e");
      setState(() => _isLoading = false);
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
      print("Error fetching messages: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final data = _communityData ?? {};
    final double headerImageHeight = 600.h;
    final double iconSize = 250.r;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE (FIXED)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerImageHeight,
            child: (data['header_url'] != null && data['header_url'] != "")
                ? CachedNetworkImage(imageUrl: data['header_url'], fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),

          // Shadow Gradient
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

          // 2. SCROLLABLE CONTENT
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // A. STICKY HEADER (ADAPTIVE DESIGN)
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                toolbarHeight: 120.h,

                // Logic Warna: Putih saat sticky, Transparan saat di atas gambar
                backgroundColor: _isSticky ? Colors.white : const Color.fromARGB(0, 0, 0, 0),
                elevation: _isSticky ? 2 : 0,
                shadowColor: Colors.black.withOpacity(0.5),
                systemOverlayStyle: _isSticky ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,

                leadingWidth: 200.w,
                leading: Padding(
                  padding: EdgeInsets.only(left: 70.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          // Logic: Base Putih saat Transparan, Hilang saat Sticky
                          color: _isSticky ? Colors.transparent : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: _isSticky
                              ? []
                              : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        // Koreksi optikal icon back ios biar center
                        padding: EdgeInsets.only(left: 22.w),
                        alignment: Alignment.center,
                        child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 60.sp),
                      ),
                    ),
                  ),
                ),

                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSticky ? 1.0 : 0.0,
                  child: Text(
                    data['name'] ?? "Community",
                    style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                centerTitle: true,
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 70.w), // 🔥 GANTI ANGKA INI BUAT GESER KIRI-KANAN
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            color: _isSticky ? Colors.transparent : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: _isSticky
                                ? []
                                : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.menu, color: Colors.black, size: 60.sp),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // B. GAP TRANSPARAN
              SliverToBoxAdapter(child: SizedBox(height: 450.h - 250.h)),

              // C. WHITE BODY + AVATAR + FLOATING BADGE
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // KOTAK PUTIH (Body)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(80.r)),
                      ),
                      padding: EdgeInsets.fromLTRB(80.w, (iconSize / 2) + 80.h, 80.w, 40.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. NAMA
                          Text(
                            data['name'] ?? "No Name",
                            style: TextStyle(fontSize: 70.sp, fontWeight: FontWeight.w600, height: 1.1),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // SUBTITLE & LOKASI
                          SizedBox(height: 0.h),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 40.sp, color: Colors.grey),
                              SizedBox(width: 0.w),
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
                                    fontWeight: FontWeight.bold,
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

                          SizedBox(height: 50.h),

                          // STATISTIK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatsItem("Tagged Post", "0"),
                              Container(height: 60.h, width: 2.w, color: Colors.grey.shade300),
                              _buildStatsItem("Members", (data['stats']?['members'] ?? 0).toString()),
                              Container(height: 60.h, width: 2.w, color: Colors.grey.shade300),
                              _buildStatsItem("Total Event", (data['stats']?['events'] ?? 0).toString()),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // AVATAR (Kiri Atas)
                    Positioned(
                      top: -(iconSize / 2),
                      left: 80.w,
                      child: Container(
                        padding: EdgeInsets.all(30.r),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: iconSize / 2,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (data['icon_url'] != null && data['icon_url'] != "")
                              ? CachedNetworkImageProvider(data['icon_url'])
                              : null,
                          child: (data['icon_url'] == null || data['icon_url'] == "")
                              ? Icon(Icons.groups, size: 80.sp, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),

                    // 🔥 BADGE VENDOR (POJOK KANAN ATAS - FLOATING)
                    Positioned(
                      top: 40.h, // Jarak dari lengkungan atas kertas putih
                      right: 60.w, // Jarak dari kanan layar
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

              // D. STICKY TAB BAR
              SliverPersistentHeader(
                pinned: true,
                delegate: _CommunityTabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: const BoxDecoration(color: Colors.blue),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
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

              // E. CONTENT TABS
              SliverFillRemaining(
                child: Container(
                  color: Colors.white,
                  child: TabBarView(controller: _tabController, children: [_buildTaggedTab(), _buildUniteTab()]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildVendorBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 6.h),
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

  Widget _buildStatsItem(String label, String count) {
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

  Widget _buildTaggedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 200.sp, color: Colors.grey.shade300),
          SizedBox(height: 30.h),
          Text(
            "This community has no post tags yet",
            style: TextStyle(fontSize: 36.sp, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUniteTab() {
    return _chatMessages.isEmpty
        ? Center(
            child: Text(
              "No discussions yet.",
              style: TextStyle(fontSize: 34.sp, color: Colors.grey),
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            itemCount: _chatMessages.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (msg['avatar_url'] != null) ? CachedNetworkImageProvider(msg['avatar_url']) : null,
                ),
                title: Text(
                  msg['username'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.sp),
                ),
                subtitle: Text(
                  msg['content'],
                  style: TextStyle(fontSize: 32.sp, color: Colors.black87),
                ),
                trailing: Text(
                  msg['created_at'].substring(11, 16),
                  style: TextStyle(fontSize: 26.sp, color: Colors.grey),
                ),
              );
            },
          );
  }
}

class _CommunityTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _CommunityTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => 100.h;
  @override
  double get maxExtent => 100.h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
