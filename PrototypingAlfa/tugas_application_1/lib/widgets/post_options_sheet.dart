import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../screens/profile/visit_profile_page.dart';

class PostOptionsSheet extends StatefulWidget {
  final Map post;
  final int currentUserId;
  final bool isSaved;
  final bool isFollowing;
  final VoidCallback onSaveToggle;
  final Function(bool) onFollowToggle;
  final VoidCallback onPostDeleted;

  const PostOptionsSheet({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.isSaved,
    required this.isFollowing,
    required this.onSaveToggle,
    required this.onFollowToggle,
    required this.onPostDeleted,
  });

  @override
  State<PostOptionsSheet> createState() => _PostOptionsSheetState();
}

class _PostOptionsSheetState extends State<PostOptionsSheet> {
  bool _isLoading = false;
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  // 🔥 FUNGSI BARU: TOAST MENGAMBANG (POPUP TENGAH) 🔥
  void _showCustomToast(String message) {
    // 1. Ambil Overlay (Lapisan Layar Paling Atas)
    final overlay = Overlay.of(context);

    // 2. Desain Popup-nya
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0, // Full Screen biar bisa Center
        child: Material(
          color: Colors.transparent, // Transparan biar belakangnya kelihatan
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 50.w), // Biar gak mepet pinggir
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 25.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5), // 🔥 Sesuai Request King
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    // 3. Tampilkan
    overlay.insert(overlayEntry);

    // 4. Hilangkan Otomatis setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  // --- LOGIC FOLLOW ---
  Future<void> _toggleFollow() async {
    setState(() => _isFollowing = !_isFollowing);
    widget.onFollowToggle(_isFollowing);

    try {
      int targetId = widget.post['author_id'] ?? widget.post['user_id'] ?? 0;
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_follow"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"follower_id": widget.currentUserId, "followed_id": targetId}),
      );

      if (response.statusCode == 200) {
        // 🔥 Ganti SnackBar jadi Toast
        _showCustomToast(_isFollowing ? "Account Followed!" : "Account Unfollowed!");
      } else {
        setState(() => _isFollowing = !_isFollowing);
        widget.onFollowToggle(_isFollowing);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
        widget.onFollowToggle(_isFollowing);
      }
    }
  }

  // --- LOGIC DELETE ---
  Future<void> _deletePost() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/delete_post"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"post_id": widget.post['id'], "user_id": widget.currentUserId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          widget.onPostDeleted();
          _showCustomToast("Postingan berhasil dihapus"); // 🔥 Toast Delete
        }
      } else {
        if (mounted) _showCustomToast("Gagal menghapus post");
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = widget.post['author_id'] == widget.currentUserId;
    if (widget.post['author_id'] == null && widget.post['user_id'] == widget.currentUserId) {
      isOwner = true;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GAGANG
          Container(
            width: 100.w,
            height: 10.h,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)),
          ),
          SizedBox(height: 50.h),

          // --- 1. SAVE & SHARE ---
          Row(
            children: [
              Expanded(
                child: _buildActionBox(
                  icon: widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: widget.isSaved ? "Unsave" : "Save",
                  onTap: () {
                    widget.onSaveToggle();
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(width: 30.w),
              Expanded(
                child: _buildActionBox(
                  icon: Icons.share,
                  label: "Share Link",
                  onTap: () {
                    Navigator.pop(context); // Tutup Menu Dulu
                    // 🔥 MUNCULIN POPUP TOAST SHARE 🔥
                    _showCustomToast("Link copied to clipboard!");
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 30.w),

          // --- 2. PERCABANGAN MENU ---
          if (isOwner)
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30.r)),
              child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(30.h),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : _buildListTile(
                      icon: Icons.delete_outline,
                      label: "Delete this post",
                      color: Colors.red,
                      onTap: _deletePost,
                    ),
            )
          else ...[
            // MENU USER LAIN
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30.r)),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.person_outline,
                    label: "Visit this profile",
                    onTap: () {
                      Navigator.pop(context);
                      int targetId = widget.post['author_id'] ?? widget.post['user_id'] ?? 0;
                      if (targetId != 0 && targetId != widget.currentUserId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisitProfilePage(
                              userId: targetId,
                              username: widget.post['username'] ?? "User",
                              visitorId: widget.currentUserId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildListTile(
                    icon: _isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
                    label: _isFollowing ? "Unfollow this account" : "Follow this account",
                    onTap: _toggleFollow,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.w),

            Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30.r)),
              child: Column(
                children: [
                  _buildListTile(icon: Icons.info_outline, label: "About this account", onTap: () {}),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildListTile(icon: Icons.help_outline, label: "Why am I seeing this post?", onTap: () {}),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildListTile(icon: Icons.visibility_off_outlined, label: "Hide this post", onTap: () {}),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildListTile(
                    icon: Icons.report_gmailerrorred,
                    label: "Report Post",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context); // Tutup Menu Dulu
                      // 🔥 MUNCULIN POPUP TOAST REPORT 🔥
                      _showCustomToast("Thanks for reporting.");
                    },
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 120.h),
        ],
      ),
    );
  }

  Widget _buildActionBox({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30.h),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30.r)),
        child: Column(
          children: [
            Icon(icon, size: 50.sp),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 50.sp),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 32.sp, color: color),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 5.h),
    );
  }
}
