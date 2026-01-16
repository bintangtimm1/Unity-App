import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 🔥 NAMA CLASS HARUS 'OwnerEventCard' (Bukan OwnerEventDetailPage)
class OwnerEventCard extends StatelessWidget {
  final String title;
  final String location;
  final String? eventImageUrl;
  final String? communityIconUrl;
  final VoidCallback onTap;

  const OwnerEventCard({
    super.key,
    required this.title,
    required this.location,
    required this.eventImageUrl,
    required this.communityIconUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Logic: Jika lokasi kosong, anggap "Online"
    String displayLocation = (location.isEmpty) ? "Online" : location;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            // 1. LOGO KOMUNITAS (KIRI)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: CircleAvatar(
                radius: 60.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (communityIconUrl != null && communityIconUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(communityIconUrl!)
                    : null,
                child: (communityIconUrl == null || communityIconUrl!.isEmpty)
                    ? Icon(Icons.groups, color: Colors.grey, size: 60.sp)
                    : null,
              ),
            ),

            // 2. TEXT INFO (TENGAH)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 42.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    displayLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // 3. EVENT IMAGE (KANAN - DECORATIVE)
            if (eventImageUrl != null && eventImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(40.r)),
                child: Container(
                  width: 250.w,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(image: CachedNetworkImageProvider(eventImageUrl!), fit: BoxFit.cover),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
