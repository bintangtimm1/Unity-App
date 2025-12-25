import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 1. IMPORT WAJIB
import '../config.dart';
import '../screens/profile_page.dart';
import '../screens/visit_profile_page.dart';
import 'comment_sheet.dart';
import 'verification_badge.dart';
import 'post_options_sheet.dart';

class PostItem extends StatefulWidget {
  final Map post;
  final int currentUserId;
  final Function(bool isLiked, int newCount)? onLikeChanged;
  final Function(bool isSaved)? onSaveChanged;
  final VoidCallback? onNavigateToProfileTab;

  const PostItem({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onLikeChanged,
    this.onSaveChanged,
    this.onNavigateToProfileTab,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool isLiked = false;
  int totalLikes = 0;
  bool isSaved = false;
  bool isDeleted = false;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    isLiked = widget.post['is_liked'] ?? false;
    totalLikes = widget.post['total_likes'] ?? 0;
    isSaved = widget.post['is_saved'] ?? false;
    isFollowing = widget.post['is_following'] ?? false;
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post['is_saved'] != isSaved) {
      setState(() => isSaved = widget.post['is_saved'] ?? false);
    }
    if (widget.post['is_liked'] != isLiked) {
      setState(() {
        isLiked = widget.post['is_liked'] ?? false;
        totalLikes = widget.post['total_likes'] ?? 0;
      });
    }
    if (widget.post['is_following'] != isFollowing) {
      setState(() => isFollowing = widget.post['is_following'] ?? false);
    }
  }

  Future<void> _toggleLike() async {
    bool oldStatus = isLiked;
    int oldTotal = totalLikes;
    setState(() {
      isLiked = !isLiked;
      totalLikes = isLiked ? totalLikes + 1 : totalLikes - 1;
    });
    if (widget.onLikeChanged != null) widget.onLikeChanged!(isLiked, totalLikes);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_like"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.currentUserId, "post_id": widget.post['id']}),
      );
      if (response.statusCode != 200) {
        setState(() {
          isLiked = oldStatus;
          totalLikes = oldTotal;
        });
      }
    } catch (e) {
      setState(() {
        isLiked = oldStatus;
        totalLikes = oldTotal;
      });
    }
  }

  Future<void> _toggleSave() async {
    bool oldStatus = isSaved;
    setState(() => isSaved = !isSaved);
    if (widget.onSaveChanged != null) widget.onSaveChanged!(isSaved);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_save"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.currentUserId, "post_id": widget.post['id']}),
      );
      if (response.statusCode != 200) {
        setState(() => isSaved = oldStatus);
        if (widget.onSaveChanged != null) widget.onSaveChanged!(oldStatus);
      }
    } catch (e) {
      setState(() => isSaved = oldStatus);
      if (widget.onSaveChanged != null) widget.onSaveChanged!(oldStatus);
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PostOptionsSheet(
          post: widget.post,
          currentUserId: widget.currentUserId,
          isSaved: isSaved,
          isFollowing: isFollowing,
          onSaveToggle: _toggleSave,
          onFollowToggle: (bool newStatus) {
            setState(() {
              isFollowing = newStatus;
            });
          },
          onPostDeleted: () {
            setState(() {
              isDeleted = true;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isDeleted) return const SizedBox.shrink();

    String safeUsername = widget.post['username'] ?? "User";
    String safeInitial = safeUsername.isNotEmpty ? safeUsername[0] : "U";

    // 🔥 LOGIC SAKTI 1: Cek Rasio dari Backend
    // Kalau backend belum support, default ke true (Square) biar aman
    bool isSquare = widget.post['is_square'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. HEADER ---
        GestureDetector(
          onTap: () {
            int authorId = widget.post['author_id'] ?? widget.post['user_id'] ?? 0;
            if (authorId == widget.currentUserId) {
              if (widget.onNavigateToProfileTab != null) widget.onNavigateToProfileTab!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VisitProfilePage(userId: authorId, username: safeUsername, visitorId: widget.currentUserId),
                ),
              );
            }
          },
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 25.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: Colors.grey.shade200,
                  child: widget.post['profile_pic_url'] != null && widget.post['profile_pic_url'] != ""
                      ? ClipOval(
                          // 🔥 LOGIC SAKTI 2: Cache Profile Picture
                          child: CachedNetworkImage(
                            imageUrl: widget.post['profile_pic_url'],
                            fit: BoxFit.cover,
                            width: 100.r,
                            height: 100.r,
                            placeholder: (context, url) => Container(color: Colors.grey.shade200),
                            errorWidget: (context, url, error) =>
                                Text(safeInitial.toUpperCase(), style: TextStyle(fontSize: 35.sp)),
                          ),
                        )
                      : Text(
                          safeInitial.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 35.sp),
                        ),
                ),
                SizedBox(width: 20.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              safeUsername,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 45.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          VerificationBadge(tier: widget.post['tier'] ?? 'regular', size: 35.sp),
                        ],
                      ),
                      if (widget.post['location_name'] != null && widget.post['location_name'] != "")
                        Text(
                          widget.post['location_name'],
                          style: TextStyle(fontSize: 32.sp, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: _showOptions,
                  child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.all(10.w),
                    child: Icon(Icons.more_horiz, color: Colors.black, size: 60.sp),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- 2. GAMBAR UTAMA (CACHE + DYNAMIC RATIO) ---
        SizedBox(
          width: 1.sw,
          child: AspectRatio(
            // 🔥 LOGIC SAKTI 3: Rasio Dinamis
            // Kalau Square (true) -> 1.0
            // Kalau Portrait (false) -> 0.8 (4:5)
            aspectRatio: isSquare ? 1.0 : 0.8,

            // 🔥 LOGIC SAKTI 4: Cache Main Image + Optimasi RAM
            child: CachedNetworkImage(
              imageUrl: widget.post['image_url'],
              fit: BoxFit.cover, // Wajib cover biar rapi
              // RESIZE DI RAM (Biar HP King gak panas walau gambar 4K)
              memCacheWidth: 1080,

              // Tampilan pas loading (Skeleton / Spinner)
              placeholder: (context, url) => Container(
                color: Colors.grey.shade100,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
              ),

              // Tampilan kalau error
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 50.sp, color: Colors.grey),
                    SizedBox(height: 10.h),
                    Text(
                      "Gagal memuat",
                      style: TextStyle(color: Colors.grey, fontSize: 24.sp),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // --- 3. ACTION BAR ---
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.black,
                  size: 80.sp,
                ),
              ),
              SizedBox(width: 24.w),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentSheet(postId: widget.post['id'], currentUserId: widget.currentUserId),
                  );
                },
                child: Image.asset('assets/images/Comment Button.png', width: 80.w, height: 80.w, fit: BoxFit.contain),
              ),
              const Spacer(),

              GestureDetector(
                onTap: _toggleSave,
                child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.black, size: 80.sp),
              ),
            ],
          ),
        ),

        // --- 4. CAPTION ---
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$totalLikes suka",
                style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 32.sp),
                  children: [
                    TextSpan(
                      text: "$safeUsername ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.post['caption'] ?? ""),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.post['created_at'] ?? "",
                style: TextStyle(fontSize: 25.sp, color: Colors.grey),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ],
    );
  }
}
