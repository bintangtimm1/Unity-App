import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/profile/visit_profile_page.dart';
import '../screens/home/notification_detail_post_page.dart';

class ApprovalItem extends StatefulWidget {
  final Map postData;
  final int currentUserId;
  final Function(int postId) onApprove;
  final Function(int postId) onReject;

  const ApprovalItem({
    super.key,
    required this.postData,
    required this.currentUserId,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ApprovalItem> createState() => _ApprovalItemState();
}

class _ApprovalItemState extends State<ApprovalItem> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    int postId = widget.postData['id'];
    int userId = widget.postData['user_id'] ?? 0;

    String rawUsername = widget.postData['username'] ?? "User";
    String userAvatar = widget.postData['user_avatar'] ?? "";
    String postImage = widget.postData['image_url'] ?? "";

    // 🔥 LOGIKA TEXT PENDEK (Saat Menu Terbuka)
    // Username: Max 8 huruf + "..."
    String displayUsername = rawUsername;
    if (_isMenuOpen && rawUsername.length > 8) {
      displayUsername = "${rawUsername.substring(0, 10)}...";
    }
    // Subtitle: Jadi "tagged this..."
    String displaySubtitle = _isMenuOpen ? "tagged this Co..." : "tagged this community";

    // Ukuran dasar
    double itemHeight = 160.h;
    double imageSize = 110.h;
    double avatarSize = 110.r;

    return Container(
      width: 1.sw,
      height: itemHeight,
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // --- 1. INFORMASI USER (TEKS) ---
          // 🔥 POSISI TETAP (Gak pake AnimatedSwitcher biar gak goyang)
          Positioned(
            left: 30.w + avatarSize + 25.w, // Mulai tepat setelah avatar
            top: 0,
            bottom: 0,
            // Lebar menyempit saat menu buka biar teks kepotong rapi sebelum kena gambar
            width: _isMenuOpen ? (1.sw - 450.w - 180.w - avatarSize) : (1.sw - 250.w - avatarSize),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // USERNAME
                GestureDetector(
                  onTap: () {
                    if (userId != 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VisitProfilePage(userId: userId, username: rawUsername, visitorId: widget.currentUserId),
                        ),
                      );
                    }
                  },
                  child: Text(
                    displayUsername, // Text berubah instan tanpa animasi geser
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34.sp, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.visible, // Biarkan '...' dari string yang handle
                  ),
                ),
                SizedBox(height: 5.h),

                // SUBTITLE
                Text(
                  displaySubtitle,
                  style: TextStyle(fontSize: 28.sp, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),

          // --- 2. AVATAR (POSISI TETAP) ---
          Positioned(
            left: 30.w,
            child: GestureDetector(
              onTap: () {
                if (userId != 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VisitProfilePage(userId: userId, username: rawUsername, visitorId: widget.currentUserId),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: userAvatar.isNotEmpty ? CachedNetworkImageProvider(userAvatar) : null,
              ),
            ),
          ),

          // --- 3. GAMBAR POSTINGAN (ANIMASI GESER) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // Geser ke kiri saat menu buka
            right: _isMenuOpen ? (1.sw - 420.w - imageSize) : 120.w,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationDetailPostPage(postId: postId, currentUserId: widget.currentUserId),
                  ),
                );
              },
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r),
                  image: postImage.isNotEmpty
                      ? DecorationImage(image: CachedNetworkImageProvider(postImage), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey.shade200,
                  boxShadow: _isMenuOpen ? [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))] : [],
                ),
              ),
            ),
          ),

          // --- 4. TOMBOL PANAH & MENU ACTION ---
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // TOMBOL PANAH (SEBAGAI HANDLE)
                GestureDetector(
                  onTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
                  child: Container(
                    width: 80.w,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // Bayangan kiri biar keliatan misah sama gambar
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(-2, 0)),
                      ],
                    ),
                    child: Icon(
                      _isMenuOpen ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                      size: 28.sp,
                      color: Colors.black54,
                    ),
                  ),
                ),

                // MENU TOMBOL (APPROVE / DECLINE)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isMenuOpen ? 450.w : 0, // Animasi lebar dari 0 ke 450
                  height: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: 450.w,
                      child: Row(
                        children: [
                          // APPROVE BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onApprove(postId),
                              child: Container(
                                color: const Color(0xFF007BFF), // Biru
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Colors.white, size: 50.sp),
                                    SizedBox(height: 5.h),
                                    Text(
                                      "Approve",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // DECLINE BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onReject(postId),
                              child: Container(
                                color: const Color(0xFFFF004D), // Merah
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.close, color: Colors.white, size: 50.sp),
                                    SizedBox(height: 5.h),
                                    Text(
                                      "Decline",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
