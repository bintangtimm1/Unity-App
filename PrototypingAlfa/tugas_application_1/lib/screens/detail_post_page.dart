import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 1. WAJIB IMPORT
import '../widgets/post_item.dart';

class DetailPostPage extends StatefulWidget {
  final String title;
  final String username;
  final List posts;
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
    _localPosts = widget.posts;

    if (widget.initialIndex > 0) {
      // 🔥 ESTIMASI POSISI SCROLL (RESPONSIF) 🔥
      // Angka 1600 adalah perkiraan tinggi 1 postingan (Header + Gambar + Action + Caption)
      double estimatedOffset = widget.initialIndex * 1600.h;
      _scrollController = ScrollController(initialScrollOffset: estimatedOffset);
    } else {
      _scrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 ANGKA TUNING POSISI (RESPONSIF) 🔒

    // 1. Tinggi Header
    final double headerHeight = 290.h;

    // 2. Posisi Tombol Back (Panah Kiri)
    final double backBtnTop = 150.h;
    final double backBtnLeft = 40.w;

    // 3. Posisi Judul & Username
    final double titleTop = 130.h;
    final double userTop = 190.h;

    return Scaffold(
      backgroundColor: Colors.white,
      // 🔥 HAPUS FittedBox, Ganti Full Screen Box
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            // --- LAYER 1: LIST POSTINGAN ---
            Positioned.fill(
              top: headerHeight, // Mulai setelah header
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _localPosts.length,
                itemBuilder: (context, index) {
                  return PostItem(
                    post: _localPosts[index],
                    currentUserId: widget.currentUserId,
                    onLikeChanged: (bool isLiked, int newCount) {
                      setState(() {
                        _localPosts[index]['is_liked'] = isLiked;
                        _localPosts[index]['total_likes'] = newCount;
                      });
                    },
                    // Callback Save juga bisa ditambah di sini kalau mau update realtime
                    onSaveChanged: (bool isSaved) {
                      setState(() {
                        _localPosts[index]['is_saved'] = isSaved;
                      });
                    },
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
                    // A. TOMBOL BACK (PANAH)
                    Positioned(
                      top: backBtnTop,
                      left: backBtnLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black, size: 80.sp),
                        onPressed: () => Navigator.pop(context, true), // Kirim true biar Profile refresh
                      ),
                    ),

                    // B. JUDUL & USERNAME (TENGAH)
                    Positioned(
                      top: 170.h,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.title, // "Creations" / "Saved"
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
