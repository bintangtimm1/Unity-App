import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event_register_page.dart'; // Halaman Register
import '../widgets/participant_card_.dart'; // 🔥 Halaman Card Baru

class UserEventDetailPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final int currentUserId;

  const UserEventDetailPage({super.key, required this.eventData, required this.currentUserId});

  @override
  State<UserEventDetailPage> createState() => _UserEventDetailPageState();
}

class _UserEventDetailPageState extends State<UserEventDetailPage> {
  // --- LOGIC FORMATTING ---
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == "null" || dateStr == "") return "-";
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yy - HH:mm a').format(date);
    } catch (e) {
      return "-";
    }
  }

  String _calculateDays() {
    try {
      DateTime start = DateTime.parse(widget.eventData['start_time']);
      DateTime end = DateTime.parse(widget.eventData['end_time']);
      int days = end.difference(start).inDays;
      return days <= 0 ? "1 Day" : "$days Days";
    } catch (e) {
      return "-";
    }
  }

  String _getRegisterStatus() {
    try {
      String? preRegStr = widget.eventData['pre_register_date'];
      String? closeRegStr = widget.eventData['close_register_date'];
      if (preRegStr == null || closeRegStr == null) return "See Description";

      DateTime now = DateTime.now();
      DateTime preReg = DateTime.parse(preRegStr);
      DateTime closeReg = DateTime.parse(closeRegStr);

      if (now.isBefore(preReg)) {
        return "Open at ${DateFormat('dd MMM').format(preReg)}";
      } else if (now.isAfter(closeReg)) {
        return "Registration Closed";
      } else {
        int daysLeft = closeReg.difference(now).inDays;
        return daysLeft == 0 ? "Closing Today!" : "$daysLeft days left";
      }
    } catch (e) {
      return "-";
    }
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link copied!"), duration: Duration(seconds: 1)));
  }

  Future<void> _launchMaps(String link) async {
    if (link.isEmpty) return;
    try {
      final Uri url = Uri.parse(link);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open maps")));
      }
    } catch (e) {
      print("Error launching maps: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.eventData;
    bool isOnline = (data['location'] == null || data['location'] == "Online" || data['location'] == "");
    String locationName = isOnline ? "This event is held online" : data['location'];
    String mapsLink = data['maps_link'] ?? "";

    // 🔥 CEK STATUS JOIN
    // Backend kirim true/false, tapi kadang string 'true'/'false' atau 1/0
    bool isJoined = data['is_joined'] == true || data['is_joined'] == 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "Event",
              style: TextStyle(color: Colors.grey, fontSize: 28.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    data['community_name'] ?? "Community",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10.w),
                Icon(Icons.verified, color: Colors.orange, size: 30.sp),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 30.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Padding(
            padding: EdgeInsets.all(40.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Event detail",
                    style: TextStyle(color: Colors.grey, fontSize: 35.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                Divider(height: 60.h),

                // 1. HEADER
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (data['community_icon'] != null && data['community_icon'] != "")
                          ? CachedNetworkImageProvider(data['community_icon'])
                          : null,
                    ),
                    SizedBox(width: 30.w),
                    Expanded(
                      child: Text(
                        data['title'] ?? "No Title",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),

                // 2. IMAGE
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      color: Colors.grey.shade200,
                      image: (data['image_url'] != null && data['image_url'] != "")
                          ? DecorationImage(image: CachedNetworkImageProvider(data['image_url']), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (data['image_url'] == null || data['image_url'] == "")
                        ? Center(
                            child: Icon(Icons.image, size: 80.sp, color: Colors.grey),
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 40.h),

                // INFO SECTION
                Text(
                  "Description",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                Text(
                  data['description'] ?? "-",
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade800, height: 1.5),
                ),
                SizedBox(height: 40.h),

                Text(
                  "Event Time",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                _buildTimeRow("Days", ":   ${_calculateDays()}"),
                _buildTimeRow("Start", ":   ${_formatDate(data['start_time'])}"),
                _buildTimeRow("End", ":   ${_formatDate(data['end_time'])}"),
                _buildTimeRow("Register", ":   ${_getRegisterStatus()}"),
                SizedBox(height: 40.h),

                Text(
                  "Event Location",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    if (!isOnline && mapsLink.isNotEmpty) _launchMaps(mapsLink);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/Googlemapslogo.png',
                          width: 60.w,
                          height: 60.w,
                          errorBuilder: (ctx, error, stack) => Icon(Icons.map, color: Colors.blue),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: Text(
                            locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (!isOnline && mapsLink.isNotEmpty)
                          GestureDetector(
                            onTap: () => _copyLink(mapsLink),
                            child: Container(
                              padding: EdgeInsets.all(15.w),
                              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                              child: Icon(Icons.link, color: Colors.black, size: 40.sp),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40.h),

                Text(
                  "Organizer",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Vendor",
                  style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                ),
                SizedBox(height: 20.h),
                _buildOrganizerCard(
                  name: data['vendor_name'] ?? "Vendor",
                  subtitle: "@${data['vendor_username'] ?? '-'}",
                  imageUrl: data['vendor_avatar'],
                  isCommunity: false,
                ),
                SizedBox(height: 40.h),
                Text(
                  "Community",
                  style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                ),
                SizedBox(height: 20.h),
                _buildOrganizerCard(
                  name: data['community_name'] ?? "Community",
                  subtitle: "Official Community",
                  imageUrl: data['community_icon'],
                  isCommunity: true,
                ),
                SizedBox(height: 60.h),

                // 🔥 TOMBOL DINAMIS (REGISTER / VIEW CARD)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isJoined) {
                        // 🅰️ SUDAH JOIN -> View Participant Card
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ParticipantCardPage(eventData: data)),
                        );
                      } else {
                        // 🅱️ BELUM JOIN -> Register
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventRegisterPage(eventData: data, userId: widget.currentUserId),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined ? Colors.white : Colors.blue, // Putih kalau joined, Biru kalau belum
                      foregroundColor: isJoined ? Colors.blue : Colors.white, // Teks Biru / Putih
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                      elevation: isJoined ? 5 : 0, // Tombol putih dikasih shadow
                      side: isJoined ? BorderSide(color: Colors.blue.shade100) : null, // Border tipis buat tombol putih
                    ),
                    child: Text(
                      isJoined ? "View Participant Card" : "Register Event",
                      style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER SAMA
  Widget _buildTimeRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard({
    required String name,
    required String subtitle,
    String? imageUrl,
    required bool isCommunity,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40.r,
          backgroundColor: isCommunity ? Colors.black : Colors.blue.shade900,
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? CachedNetworkImageProvider(imageUrl) : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0] : "?",
                  style: TextStyle(color: Colors.white, fontSize: 30.sp),
                )
              : null,
        ),
        SizedBox(width: 30.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Icon(Icons.verified, color: Colors.orange, size: 30.sp),
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 28.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
