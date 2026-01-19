import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../config.dart';

class EventParticipantsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const EventParticipantsPage({super.key, required this.eventId, required this.eventTitle});

  @override
  State<EventParticipantsPage> createState() => _EventParticipantsPageState();
}

class _EventParticipantsPageState extends State<EventParticipantsPage> {
  List _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_event_participants?event_id=${widget.eventId}"));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _participants = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching participants: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM, HH:mm').format(date);
    } catch (e) {
      return "-";
    }
  }

  void _showParticipantDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(60.r))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20.h),
          child: Container(
            padding: EdgeInsets.all(40.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 100.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 160, 160, 160),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  "Participant Detail",
                  style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40.h),

                _detailRow(Icons.person, "Name", user['full_name']),
                _detailRow(Icons.alternate_email, "Username", "@${user['username']}"),
                _detailRow(Icons.email_outlined, "Email", user['email']),
                _detailRow(Icons.phone_android, "Phone", user['phone']),
                _detailRow(Icons.calendar_today, "Registered", _formatDate(user['joined_at'])),

                SizedBox(height: 20.h), // Jarak tambahan di bawah
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 25.h),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 85, 85, 85), size: 40.sp),
          SizedBox(width: 30.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey, fontSize: 34.sp),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Participants",
          style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
            color: const Color.fromARGB(255, 255, 255, 255),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventTitle,
                  style: TextStyle(fontSize: 32.sp, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${_participants.length} Registered",
                  style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _participants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 150.sp, color: Colors.grey.shade300),
                        SizedBox(height: 20.h),
                        Text(
                          "No participants yet",
                          style: TextStyle(fontSize: 34.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 20.h),

                    itemCount: _participants.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 120.w, // Mulai setelah avatar
                      endIndent: 40.w,
                    ),

                    itemBuilder: (context, index) {
                      final p = _participants[index];

                      return ListTile(
                        onTap: () => _showParticipantDetail(p),
                        contentPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),

                        leading: CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (p['profile_pic'] != null && p['profile_pic'] != "")
                              ? CachedNetworkImageProvider(p['profile_pic'])
                              : null,
                          child: (p['profile_pic'] == null || p['profile_pic'] == "")
                              ? Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          p['full_name'],
                          style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 0.h),
                          child: Text(
                            "@${p['username']} • ${p['phone']}",
                            style: TextStyle(fontSize: 32.sp, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 40.sp),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
