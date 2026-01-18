import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ParticipantCardPage extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const ParticipantCardPage({super.key, required this.eventData});

  // Helper Date
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == "") return "-";
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data Event
    String bgImage = eventData['image_url'] ?? "";
    String title = eventData['title'] ?? "Event Title";
    String dateStr = _formatDate(eventData['start_time']);
    String location = (eventData['location'] == null || eventData['location'] == "") ? "Online" : eventData['location'];
    String communityName = eventData['community_name'] ?? "Community";
    String communityIcon = eventData['community_icon'] ?? "";

    // 🔥 DATA PESERTA REAL DARI BACKEND
    // Kalau null (data lama), default ke "Verified Member"
    String participantName = eventData['participant_name'] ?? "Verified Member";

    // Tiket ID Dummy
    String ticketId = "TIX-${eventData['id']}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white, size: 30.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Your Ticket",
          style: TextStyle(color: Colors.white, fontSize: 34.sp),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
          child: AspectRatio(
            aspectRatio: 3 / 4.2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: Offset(0, 15))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // =============================
                        // BAGIAN ATAS (GELAP - EVENT INFO)
                        // =============================
                        Expanded(
                          flex: 6,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (bgImage.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: bgImage,
                                  fit: BoxFit.cover,
                                  color: Colors.black.withOpacity(0.8),
                                  colorBlendMode: BlendMode.darken,
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.blue.shade900.withOpacity(0.6), Colors.black.withOpacity(0.9)],
                                  ),
                                ),
                              ),

                              Padding(
                                padding: EdgeInsets.all(40.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Community
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30.r,
                                          backgroundColor: Colors.white24,
                                          backgroundImage: (communityIcon.isNotEmpty)
                                              ? CachedNetworkImageProvider(communityIcon)
                                              : null,
                                        ),
                                        SizedBox(width: 15.w),
                                        Expanded(
                                          child: Text(
                                            communityName.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 30.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 30.h),

                                    // Judul Event
                                    Text(
                                      title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 64.sp,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),

                                    Spacer(),
                                    Divider(color: Colors.white24),
                                    SizedBox(height: 20.h),
                                    _buildTicketInfo(Icons.calendar_today, dateStr),
                                    SizedBox(height: 15.h),
                                    _buildTicketInfo(Icons.location_on, location),
                                    SizedBox(height: 20.h),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // =============================
                        // GARIS PUTUS-PUTUS (SEPARATOR)
                        // =============================
                        Container(
                          color: Colors.white,
                          height: 40.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                children: List.generate(
                                  30,
                                  (index) => Expanded(
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                                      height: 4.h,
                                      color: const Color.fromARGB(255, 182, 182, 182),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -20.w,
                                child: CircleAvatar(radius: 20.w, backgroundColor: Colors.grey.shade900),
                              ),
                              Positioned(
                                right: -20.w,
                                child: CircleAvatar(radius: 20.w, backgroundColor: Colors.grey.shade900),
                              ),
                            ],
                          ),
                        ),

                        // =============================
                        // BAGIAN BAWAH (PUTIH - PARTICIPANT INFO)
                        // =============================
                        Expanded(
                          flex: 4,
                          child: Container(
                            color: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Info Peserta
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "PARTICIPANT",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 28.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 5.h),

                                          // 🔥 UPDATE: TAMPILKAN NAMA PESERTA ASLI
                                          Text(
                                            participantName, // <-- Variabel baru
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 50.sp,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                          ),

                                          SizedBox(height: 30.h),
                                          Text(
                                            "TICKET ID",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 28.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 5.h),
                                          Text(
                                            ticketId,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 35.sp,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    // QR Code
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        height: 220.w,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.black, width: 2),
                                          borderRadius: BorderRadius.circular(25.r),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.qr_code_2_rounded, size: 200.w, color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Show this code at the venue entrance.",
                                  style: TextStyle(color: Colors.grey, fontSize: 24.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Positioned(
                      right: -50.w,
                      top: 250.h,
                      child: Transform.rotate(
                        angle: -math.pi / 2,
                        child: Text(
                          "ADMIT ONE",
                          style: TextStyle(
                            color: Colors.white10,
                            fontSize: 100.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 36.sp),
        SizedBox(width: 15.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 35.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
