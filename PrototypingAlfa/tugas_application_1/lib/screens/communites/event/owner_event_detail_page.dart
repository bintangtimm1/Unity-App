import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // 🔥 1. WAJIB IMPORT INI
import '../../../config.dart';
import '../../profile/profile_page.dart';
import '../../event_participants_page.dart';

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

  // 🔥 2. FUNGSI BUKA MAPS LANGSUNG
  Future<void> _launchMaps(String link) async {
    if (link.isEmpty) return;
    try {
      final Uri url = Uri.parse(link);
      // Mode externalApplication biar buka App Google Maps beneran
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

    if (_isDeleting) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true, // 🔥 WAJIB TRUE BIAR TENGAH
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            // 1. TULISAN "Event" (Kecil Abu-abu)
            Text(
              "Event",
              style: TextStyle(color: Colors.grey, fontSize: 28.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5.h), // Jarak dikit
            // 2. NAMA KOMUNITAS + ICON (Besar Hitam)
            Row(
              mainAxisSize: MainAxisSize.min, // Biar Row-nya ngebungkus teks aja (gak full width)
              children: [
                Flexible(
                  // Pakai Flexible biar kalau nama panjang dia gak error
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

                // 5. LOCATION (UPDATED 🔥)
                Text(
                  "Event Location",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),

                // 🔥 WRAP CONTAINER DENGAN GESTURE DETECTOR
                GestureDetector(
                  onTap: () {
                    // Kalau ditekan kotaknya, buka Maps
                    if (!isOnline && mapsLink.isNotEmpty) {
                      _launchMaps(mapsLink);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white, // Tambah warna biar tap area jelas
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
                          // 🔥 TOMBOL COPY LINK (TETAP ADA)
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

                // 6. ORGANIZER
                Text(
                  "Organizer",
                  style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h), // Jarak agak jauh dikit dari judul
                // A. VENDOR
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

                SizedBox(height: 40.h), // Jarak pemisah Vendor & Community
                // B. COMMUNITY
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

                SizedBox(height: 60.h),

                // 7. BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // 🔥 NAVIGASI KE LIST PESERTA
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventParticipantsPage(eventId: data['id'], eventTitle: data['title'] ?? "Event"),
                        ),
                      );
                    },
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

  // 🔥 VERSI BERSIH: TANPA KOTAK, TANPA KLIK
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
        // ❌ HAPUS ICON PANAH (CHEVRON)
      ],
    );
  }
}
