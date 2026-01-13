import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'verification_badge.dart'; // Pastikan import badge yang sudah ada

class UniteItem extends StatelessWidget {
  final Map message;
  final int currentUserId;
  final int communityOwnerId; // Butuh ini buat izin delete
  final Function(int messageId) onDelete;

  const UniteItem({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.communityOwnerId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    int msgId = message['id'];
    int authorId = message['user_id'] ?? 0; // Pastikan backend kirim user_id
    String username = message['username'] ?? "User";
    String avatarUrl = message['avatar_url'] ?? "";
    String content = message['content'] ?? "";
    String tier = message['tier'] ?? 'regular';
    DateTime created = DateTime.parse(message['created_at']);

    // Logic: Boleh delete kalau dia AUTHOR atau OWNER KOMUNITAS
    bool canDelete = (currentUserId == authorId) || (currentUserId == communityOwnerId);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 25.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. AVATAR
          CircleAvatar(
            radius: 55.r,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.grey, size: 55.sp) : null,
          ),
          SizedBox(width: 30.w),

          // 2. KONTEN (KANAN)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER (NAMA + BADGE + MENU)
                Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36.sp),
                    ),
                    SizedBox(width: 10.w),
                    // Tampilkan Badge kalau bukan regular
                    if (tier != 'regular') VerificationBadge(tier: tier, size: 36.sp),

                    const Spacer(),

                    // MENU DELETE (Hanya jika punya akses)
                    if (canDelete)
                      GestureDetector(
                        onTap: () => onDelete(msgId),
                        child: Icon(Icons.more_horiz, color: Colors.grey, size: 40.sp),
                      ),
                  ],
                ),

                // ISI PESAN
                SizedBox(height: 5.h),
                Text(
                  content,
                  style: TextStyle(fontSize: 34.sp, color: Colors.black87, height: 1.3),
                ),

                SizedBox(height: 25.h),

                // FOOTER (ICONS & TIME)
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 40.sp, color: Colors.black),
                    SizedBox(width: 40.w),
                    Icon(Icons.favorite_border, size: 40.sp, color: Colors.black),
                    const Spacer(),
                    Text(
                      timeago.format(created, locale: 'en_short'), // ex: 1h, 5m
                      style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
