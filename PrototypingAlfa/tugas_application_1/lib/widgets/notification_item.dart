import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../screens/profile/visit_profile_page.dart';
import '../screens/home/notification_detail_post_page.dart';

class NotificationItem extends StatelessWidget {
  final Map notif;
  final int currentUserId;

  const NotificationItem({super.key, required this.notif, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari notif
    int senderId = notif['sender_id'];

    // 🔥 UPDATE: PRIORITASKAN DISPLAY NAME
    String senderName = notif['sender_display_name'] ?? notif['sender_username'] ?? "User";
    String rawUsername = notif['sender_username'] ?? "User"; // Username asli buat navigasi (opsional)

    String senderAvatar = notif['sender_profile_pic'] ?? "";
    String type = notif['type'];
    String? postImage = notif['post_image_url'];
    int? postId = notif['post_id'];
    bool isRead = notif['is_read'] ?? true;

    // Pesan berdasarkan tipe
    String message = "";
    if (type == 'like')
      message = "liked your post.";
    else if (type == 'comment')
      message = "commented: ${notif['message'] ?? ''}";
    else if (type == 'follow')
      message = "started following you.";

    return Container(
      color: isRead ? Colors.white : Colors.blue.withOpacity(0.05), // Highlight kalau belum baca
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 25.h),
      child: Row(
        children: [
          // --- 1. AVATAR (KLIK -> KE PROFILE) ---
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VisitProfilePage(userId: senderId, username: senderName, visitorId: currentUserId),
                ),
              );
            },
            child: CircleAvatar(
              radius: 60.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: senderAvatar.isNotEmpty ? CachedNetworkImageProvider(senderAvatar) : null,
              child: senderAvatar.isEmpty ? Icon(Icons.person, color: Colors.grey, size: 60.sp) : null,
            ),
          ),
          SizedBox(width: 30.w),

          // --- 2. TEKS (KLIK NAMA -> KE PROFILE) ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VisitProfilePage(userId: senderId, username: senderName, visitorId: currentUserId),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 36.sp),
                      children: [
                        TextSpan(
                          text: "$senderName ", // 🔥 INI SUDAH DISPLAY NAME
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: message),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  timeago.format(DateTime.parse(notif['created_at'])),
                  style: TextStyle(color: Colors.grey, fontSize: 30.sp),
                ),
              ],
            ),
          ),

          // --- 3. GAMBAR POSTINGAN (KLIK -> KE DETAIL POST) ---
          if ((type == 'like' || type == 'comment') && postImage != null && postId != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationDetailPostPage(postId: postId, currentUserId: currentUserId),
                  ),
                );
              },
              child: Container(
                width: 120.w,
                height: 120.w,
                margin: EdgeInsets.only(left: 20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  image: DecorationImage(image: CachedNetworkImageProvider(postImage), fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
