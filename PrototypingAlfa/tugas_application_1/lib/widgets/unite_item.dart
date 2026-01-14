import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'verification_badge.dart';
import 'unite_menu_sheet.dart';

class UniteItem extends StatelessWidget {
  final Map message;
  final int currentUserId;
  final int communityOwnerId;
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

    // 🔥 FIX LOGIKA ID: Paksa jadi String dulu baru parse ke Int biar aman
    int authorId = int.tryParse(message['user_id'].toString()) ?? 0;

    String username = message['username'] ?? "User";
    String avatarUrl = message['avatar_url'] ?? "";

    // CONTENT FULL (Twitter Style)
    String content = message['content'] ?? "";

    String tier = message['tier'] ?? 'regular';
    DateTime created = DateTime.parse(message['created_at']);

    // 🔥 LOGIKA PERMISSION (Sekarang pasti akurat)
    bool isOwner = (currentUserId == communityOwnerId);
    bool isAuthor = (currentUserId == authorId);

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
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          if (tier != 'regular') VerificationBadge(tier: tier, size: 36.sp),
                        ],
                      ),
                    ),

                    SizedBox(width: 20.w),

                    // MENU BUTTON
                    // MENU BUTTON
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => UniteMenuSheet(
                            message: message,
                            isOwner: isOwner,
                            isAuthor: isAuthor,
                            currentUserId: currentUserId, // 🔥 PASSING ID KITA KE MENU
                            onDelete: () => onDelete(msgId),
                          ),
                        );
                      },
                      child: Icon(Icons.more_horiz, color: Colors.grey, size: 40.sp),
                    ),
                  ],
                ),

                SizedBox(height: 5.h),

                // ISI PESAN (FULL TEXT)
                Padding(
                  padding: EdgeInsets.only(right: 60.w),
                  child: Text(
                    content,
                    style: TextStyle(fontSize: 34.sp, color: Colors.black87, height: 1.3),
                  ),
                ),

                SizedBox(height: 25.h),

                // FOOTER
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 40.sp, color: Colors.black),
                    SizedBox(width: 40.w),
                    Icon(Icons.favorite_border, size: 40.sp, color: Colors.black),
                    const Spacer(),
                    Text(
                      timeago.format(created, locale: 'en_short'),
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
