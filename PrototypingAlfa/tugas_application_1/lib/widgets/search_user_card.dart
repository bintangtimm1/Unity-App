import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const SearchUserCard({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Cek Tier untuk Centang
    String tier = (user['tier'] ?? 'regular').toLowerCase();
    bool isVerified = tier == 'vendor' || tier == 'gold' || tier == 'verified';
    Color badgeColor = (tier == 'gold') ? Colors.orange : Colors.blue;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 5.h),
      // 1. FOTO PROFIL
      leading: CircleAvatar(
        radius: 55.r,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (user['profile_pic_url'] != null && user['profile_pic_url'] != "")
            ? CachedNetworkImageProvider(user['profile_pic_url'])
            : null,
        child: (user['profile_pic_url'] == null || user['profile_pic_url'] == "")
            ? Icon(Icons.person, color: Colors.grey, size: 40.sp)
            : null,
      ),
      // 2. NAMA & USERNAME
      title: Row(
        children: [
          Flexible(
            child: Text(
              user['username'] ?? "User",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          if (isVerified) ...[SizedBox(width: 10.w), Icon(Icons.verified, size: 35.sp, color: badgeColor)],
        ],
      ),
      subtitle: Text(
        "${user['display_name'] ?? '-'}",
        style: TextStyle(fontSize: 30.sp, color: Colors.grey, fontWeight: FontWeight.w500),
      ),
      // 3. PANAH KE KANAN
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 40.sp),
    );
  }
}
