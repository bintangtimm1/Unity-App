import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class NotificationItem extends StatefulWidget {
  final Map notif;
  final int currentUserId;

  const NotificationItem({super.key, required this.notif, required this.currentUserId});

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  late bool isFollowing;
  bool isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.notif['is_following_sender'] ?? false;
  }

  // 🔥 FUNGSI BARU: UBAH TANGGAL JADI '5m', '2h', '3d'
  String _getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "";
    try {
      // Backend kirim "2025-12-25 19:43:03", Dart butuh ada 'T' di tengah biar valid ISO-8601
      // Jadi kita ganti spasi jadi 'T' dulu
      DateTime notifDate = DateTime.parse(dateString.replaceAll(" ", "T"));
      Duration diff = DateTime.now().difference(notifDate);

      if (diff.inDays > 30) {
        // Kalau lebih dari sebulan: Tampilkan Tanggal (25/12/2025)
        return "${notifDate.day}/${notifDate.month}/${notifDate.year}";
      } else if (diff.inDays >= 1) {
        // Kalau harian: 3d (3 days)
        return "${diff.inDays}d";
      } else if (diff.inHours >= 1) {
        // Kalau jam: 2h (2 hours)
        return "${diff.inHours}h";
      } else if (diff.inMinutes >= 1) {
        // Kalau menit: 5m (5 minutes)
        return "${diff.inMinutes}m";
      } else {
        return "now"; // Baru banget
      }
    } catch (e) {
      return dateString; // Kalau error parsing, balikin string aslinya
    }
  }

  Future<void> _toggleFollowBack() async {
    setState(() => isLoadingFollow = true);
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_follow"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"follower_id": widget.currentUserId, "followed_id": widget.notif['sender_id']}),
      );

      if (response.statusCode == 200) {
        setState(() => isFollowing = !isFollowing);
      }
    } catch (e) {
      print("Error follow back: $e");
    } finally {
      setState(() => isLoadingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String type = widget.notif['type'];
    String username = widget.notif['sender_username'] ?? "User";
    String profilePic = widget.notif['sender_profile_pic'] ?? "";
    String? postImage = widget.notif['post_image_url'];
    String message = widget.notif['message'] ?? "";

    // 🔥 PANGGIL FUNGSI WAKTU DISINI
    String timeAgo = _getTimeAgo(widget.notif['created_at']);

    String contentText = "";
    if (type == 'like')
      contentText = "menyukai postingan anda.";
    else if (type == 'comment')
      contentText = "mengomentari: \"$message\"";
    else if (type == 'follow')
      contentText = "mulai mengikuti anda.";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
      child: Row(
        children: [
          // 1. FOTO PROFIL
          GestureDetector(
            onTap: () {
              // Nanti bisa navigate ke profil orangnya
            },
            child: CircleAvatar(
              radius: 50.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (profilePic.isNotEmpty) ? CachedNetworkImageProvider(profilePic) : null,
              child: (profilePic.isEmpty) ? Icon(Icons.person, color: Colors.grey, size: 50.sp) : null,
            ),
          ),
          SizedBox(width: 30.w),

          // 2. TEKS TENGAH + WAKTU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 32.sp),
                    children: [
                      TextSpan(
                        text: "$username ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: contentText),
                      // Waktu kita taruh di ujung teks dengan warna abu
                      TextSpan(
                        text: "  $timeAgo",
                        style: TextStyle(color: Colors.grey, fontSize: 28.sp),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),

          // 3. ACTION KANAN
          if (type == 'follow')
            GestureDetector(
              onTap: isLoadingFollow ? null : _toggleFollowBack,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.grey.shade200 : Colors.blue,
                  borderRadius: BorderRadius.circular(30.r),
                  border: isFollowing ? Border.all(color: Colors.grey.shade400) : null,
                ),
                child: isLoadingFollow
                    ? SizedBox(
                        width: 30.w,
                        height: 30.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isFollowing ? "Following" : "Follow Back",
                        style: TextStyle(
                          color: isFollowing ? Colors.black : Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )
          else if ((type == 'like' || type == 'comment') && postImage != null)
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                image: DecorationImage(image: CachedNetworkImageProvider(postImage), fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}
