import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'profile_page.dart'; // 🔥 IMPORT PROFILE PAGE

class OwnerEventDetailPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final int currentUserId;

  const OwnerEventDetailPage({super.key, required this.eventData, required this.currentUserId});

  @override
  State<OwnerEventDetailPage> createState() => _OwnerEventDetailPageState();
}

class _OwnerEventDetailPageState extends State<OwnerEventDetailPage> {
  bool _isDeleting = false;

  // --- LOGIC HAPUS EVENT ---
  Future<void> _deleteEvent() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Delete Event?",
          style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        content: Text("Are you sure you want to cancel this event? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(fontSize: 35.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 35.sp),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/delete_event"),
        body: {"user_id": widget.currentUserId.toString(), "event_id": widget.eventData['id'].toString()},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Event deleted successfully")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete event")));
      }
    } catch (e) {
      print("Error deleting: $e");
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final data = widget.eventData;
    bool isOnline = (data['location'] == null || data['location'] == "Online" || data['location'] == "");
    String locationName = isOnline ? "This event is held online" : data['location'];
    String mapsLink = data['maps_link'] ?? "";

    if (_isDeleting) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                data['community_name'] ?? "Community",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 10.w),
            Icon(Icons.verified, color: Colors.orange, size: 30.sp),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: Colors.black),
            onSelected: (value) {
              if (value == 'delete') _deleteEvent();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 10.w),
                    Text('Delete Event', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 30.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Padding(
            padding: EdgeInsets.all(40.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 100.w, height: 4.h, color: Colors.grey.shade300),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Text(
                    "Event detail",
                    style: TextStyle(color: Colors.grey, fontSize: 30.sp),
                  ),
                ),
                Divider(height: 40.h),

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

                // 3. DESCRIPTION
                Text(
                  "Description",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                Text(
                  data['description'] ?? "No description.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade800, height: 1.5),
                ),
                SizedBox(height: 40.h),

                // 4. EVENT TIME
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

                // 5. LOCATION
                Text(
                  "Event Location",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(color: Colors.grey.shade300),
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
                SizedBox(height: 40.h),

                // 6. ORGANIZER (DENGAN NAVIGASI KE PROFILE)
                Text(
                  "Organizer",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.h),

                Text(
                  "Vendor",
                  style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                ),
                SizedBox(height: 10.h),
                // 🔥 KARTU VENDOR (KLIK -> PROFILE)
                _buildOrganizerCard(
                  name: data['vendor_name'] ?? "Vendor",
                  subtitle: "@${data['vendor_username'] ?? '-'}",
                  imageUrl: data['vendor_avatar'],
                  isCommunity: false,
                  onTap: () {
                    // 🔥 NAVIGASI KE PROFIL USER (OWNER)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.currentUserId)),
                    );
                  },
                ),

                SizedBox(height: 20.h),
                Text(
                  "Community",
                  style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                ),
                SizedBox(height: 10.h),
                // 🔥 KARTU COMMUNITY (DEFAULT)
                _buildOrganizerCard(
                  name: data['community_name'] ?? "Community",
                  subtitle: "Official Community",
                  imageUrl: data['community_icon'],
                  isCommunity: true,
                  onTap: () {
                    // Logic ke Profile Community (Belum ada ID Community di response,
                    // kalau butuh bisa request update backend lagi)
                  },
                ),

                SizedBox(height: 60.h),

                // 7. BUTTON (DUMMY)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      side: BorderSide(color: Colors.blue.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                    ),
                    child: Text(
                      "View Participant",
                      style: TextStyle(fontSize: 36.sp, color: Colors.blue, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 UPDATE: WIDGET BISA DIKLIK (ADA ONTAP & PANAH)
  Widget _buildOrganizerCard({
    required String name,
    required String subtitle,
    String? imageUrl,
    required bool isCommunity,
    VoidCallback? onTap, // Parameter baru
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
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
            // Tampilkan panah kalau Community atau kalau ada onTap (bisa diklik)
            if (isCommunity || onTap != null) Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
