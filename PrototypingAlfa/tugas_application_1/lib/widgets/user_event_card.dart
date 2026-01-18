import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class UserEventCard extends StatelessWidget {
  final String title;
  final String startDate; // Format: "2026-01-25"
  final String endDate; // Format: "2026-01-30"
  final String? posterUrl;
  final String? communityIconUrl;
  final VoidCallback onTapDetail;

  const UserEventCard({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.posterUrl,
    required this.communityIconUrl,
    required this.onTapDetail,
  });

  String _formatDateRange() {
    try {
      DateTime start = DateTime.parse(startDate);
      DateTime end = DateTime.parse(endDate);
      String startStr = DateFormat('d MMMM').format(start);
      String endStr = DateFormat('d MMMM').format(end);
      return "$startStr  -  $endStr";
    } catch (e) {
      return startDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320.h,
      // 🔥 UPDATE SHADOW: Dibuat rata semua sisi (offset 0, spread ada)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Sedikit lebih gelap biar kontras
            blurRadius: 5, // Blur lebih luas
            spreadRadius: 2, // Melebar ke segala arah
            offset: Offset.zero, // Bayangan rata tengah (atas bawah kiri kanan kena)
          ),
        ],
      ),
      child: Row(
        children: [
          // ==========================================
          // 1. BAGIAN KIRI (POSTER + LOGO KOMUNITAS)
          // ==========================================
          SizedBox(
            width: 300.w,
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // A. BACKGROUND POSTER
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40.r), bottomLeft: Radius.circular(40.r)),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: (posterUrl != null && posterUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(posterUrl!)
                            : const AssetImage('assets/images/placeholder_event.jpg') as ImageProvider,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                      ),
                    ),
                  ),
                ),

                // B. LOGO KOMUNITAS (TENGAH)
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 70.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (communityIconUrl != null && communityIconUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(communityIconUrl!)
                            : null,
                        child: (communityIconUrl == null || communityIconUrl!.isEmpty)
                            ? Icon(Icons.groups, size: 50.sp, color: Colors.grey)
                            : null,
                      ),
                    ),
                    // 🔥 UPDATE: CENTANG GOLD (ORANGE)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.verified, color: Colors.orange, size: 40.sp), // Warna diganti Orange/Gold
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. BAGIAN KANAN (INFO + TOMBOL)
          // ==========================================
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Judul & Tanggal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        _formatDateRange(),
                        style: TextStyle(fontSize: 30.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  // Tombol "Event Detail"
                  SizedBox(
                    width: double.infinity,
                    height: 80.h,
                    child: ElevatedButton(
                      onPressed: onTapDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      ),
                      child: Text(
                        "Event Detail",
                        style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
