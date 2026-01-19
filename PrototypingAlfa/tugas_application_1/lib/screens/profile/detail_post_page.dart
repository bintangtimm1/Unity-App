import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/post_item.dart';

class DetailPostPage extends StatefulWidget {
  final String title;
  final String username;
  final List posts; // Data mentah dari halaman sebelumnya
  final int initialIndex;
  final int currentUserId;

  const DetailPostPage({
    super.key,
    required this.title,
    required this.username,
    required this.posts,
    required this.initialIndex,
    required this.currentUserId,
  });

  @override
  State<DetailPostPage> createState() => _DetailPostPageState();
}

class _DetailPostPageState extends State<DetailPostPage> {
  late ScrollController _scrollController;
  late List _localPosts;

  @override
  void initState() {
    super.initState();
    _sanitizeAndLoadData();

    // SCROLL LOGIC
    if (widget.initialIndex > 0) {
      double estimatedOffset = widget.initialIndex * 1600.h;
      _scrollController = ScrollController(initialScrollOffset: estimatedOffset);
    } else {
      _scrollController = ScrollController();
    }
  }

  // 🔥 FUNGSI PEMBERSIH DATA (Dipisah biar rapi)
  void _sanitizeAndLoadData() {
    // Kita copy list-nya biar aman
    _localPosts = List.from(widget.posts).map((post) {
      // 1. Fix Like Status
      // Kalau datanya 1 atau '1', paksa jadi TRUE
      if (post['is_liked'] == 1 || post['is_liked'] == '1') {
        post['is_liked'] = true;
        print("DEBUG: Post ID ${post['id']} status LIKE diperbaiki jadi TRUE");
      }
      // Kalau datanya 0, '0', atau null, paksa jadi FALSE
      else if (post['is_liked'] == 0 || post['is_liked'] == '0' || post['is_liked'] == null) {
        post['is_liked'] = false;
      }

      // 2. Fix Saved Status
      if (post['is_saved'] == 1 || post['is_saved'] == '1') {
        post['is_saved'] = true;
      } else if (post['is_saved'] == 0 || post['is_saved'] == '0' || post['is_saved'] == null) {
        post['is_saved'] = false;
      }

      return post;
    }).toList();

    setState(() {}); // Refresh UI setelah data bersih
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = 290.h;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            // --- LAYER 1: LIST POSTINGAN ---
            Positioned.fill(
              top: headerHeight,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _localPosts.length,
                itemBuilder: (context, index) {
                  return PostItem(
                    post: _localPosts[index],
                    currentUserId: widget.currentUserId,

                    // UPDATE STATE SAAT LIKE DI-KLIK DI SINI
                    onLikeChanged: (bool isLiked, int newCount) {
                      setState(() {
                        _localPosts[index]['is_liked'] = isLiked;
                        _localPosts[index]['total_likes'] = newCount;
                      });
                    },
                    onSaveChanged: (bool isSaved) {
                      setState(() {
                        _localPosts[index]['is_saved'] = isSaved;
                      });
                    },
                    onNavigateToProfileTab: () {},
                  );
                },
              ),
            ),

            // --- LAYER 2: CUSTOM HEADER ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.r, offset: Offset(0, 5.h)),
                  ],
                ),
                child: Stack(
                  children: [
                    // TOMBOL BACK
                    Positioned(
                      top: 150.h,
                      left: 40.w,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 65.sp),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ),
                    // JUDUL & USERNAME
                    Positioned(
                      top: 170.h,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 40.sp),
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 210.h,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.username,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 35.sp, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
