import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchCommunityCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final VoidCallback onTap;

  const SearchCommunityCard({super.key, required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            // 1. ICON COMMUNITY
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                image: (community['icon_url'] != null && community['icon_url'] != "")
                    ? DecorationImage(image: CachedNetworkImageProvider(community['icon_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: (community['icon_url'] == null || community['icon_url'] == "")
                  ? Icon(Icons.groups, color: Colors.grey, size: 50.sp)
                  : null,
            ),
            SizedBox(width: 30.w),

            // 2. INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community['name'] ?? "Community Name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    "${community['member_count'] ?? 0} Members",
                    style: TextStyle(fontSize: 26.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 3. TOMBOL JOIN / VIEW (Kecil aja)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20.r)),
              child: Text(
                "View",
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
