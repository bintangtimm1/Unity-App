import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'verification_badge.dart';
import '../screens/visit_profile_page.dart';

class UniteMenuSheet extends StatelessWidget {
  final Map message;
  final bool isOwner;
  final bool isAuthor;
  final int currentUserId;
  final Function() onDelete;

  const UniteMenuSheet({
    super.key,
    required this.message,
    required this.isOwner,
    required this.isAuthor,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 LOGIKA DISPLAY NAME
    String displayName = message['display_name'] ?? message['username'] ?? "User";

    String avatarUrl = message['avatar_url'] ?? "";
    String tier = message['tier'] ?? 'regular';
    String content = message['content'] ?? "";

    DateTime created = DateTime.parse(message['created_at']);
    String timeString = timeago.format(created, locale: 'en_short');

    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER USER ---
          Row(
            children: [
              CircleAvatar(
                radius: 60.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
              ),
              SizedBox(width: 25.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName, // 🔥 PAKAI DISPLAY NAME
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40.sp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        if (tier != 'regular') VerificationBadge(tier: tier, size: 40.sp),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: Text(
                        content,
                        style: TextStyle(color: Colors.black, fontSize: 35.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20.w),
              Text(
                timeString,
                style: TextStyle(color: Colors.grey, fontSize: 28.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          Divider(height: 50.h, color: Colors.grey.shade300),

          // --- ACTIONS ---
          Text(
            "Actions",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.sp),
          ),
          SizedBox(height: 20.h),

          Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30.r)),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.push_pin_outlined,
                  label: "Pin this unite",
                  onTap: () => Navigator.pop(context),
                ),
                if (isOwner) ...[
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildMenuItem(
                    icon: Icons.assignment_turned_in_outlined,
                    label: "Pin for All",
                    onTap: () => Navigator.pop(context),
                  ),
                ],

                // 3. TOMBOL VISIT PROFILE
                if (!isAuthor) ...[
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: "About this Member",
                    onTap: () {
                      Navigator.pop(context);

                      int memberId = int.tryParse(message['user_id'].toString()) ?? 0;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisitProfilePage(
                            userId: memberId,
                            username: displayName, // 🔥 Kirim Nama Panggung biar header langsung bener
                            visitorId: currentUserId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 30.h),

          // --- MORE ---
          Text(
            "More",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.sp),
          ),
          SizedBox(height: 20.h),

          // --- DELETE / REPORT ---
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30.r)),
            child: (isOwner || isAuthor)
                ? _buildMenuItem(
                    icon: Icons.delete_outline,
                    label: "Delete this Unite",
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  )
                : _buildMenuItem(
                    icon: Icons.report_gmailerrorred,
                    label: "Report this Unite",
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted.")));
                    },
                  ),
          ),

          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 35.h),
        child: Row(
          children: [
            Icon(icon, size: 50.sp, color: isDestructive ? Colors.red : Colors.black87),
            SizedBox(width: 30.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 34.sp,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
