import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config.dart';

class SelectOrganizerPage extends StatefulWidget {
  final int userId;
  const SelectOrganizerPage({super.key, required this.userId});

  @override
  State<SelectOrganizerPage> createState() => _SelectOrganizerPageState();
}

class _SelectOrganizerPageState extends State<SelectOrganizerPage> {
  List _myCommunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyCommunities();
  }

  Future<void> _fetchMyCommunities() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/get_my_communities_for_event?user_id=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _myCommunities = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 150.w,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Back",
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 0, 55),
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          "Select Organizer",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myCommunities.isEmpty
          ? Center(
              child: Text(
                "You don't have any community yet.",
                style: TextStyle(fontSize: 35.sp, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
              itemCount: _myCommunities.length,
              separatorBuilder: (_, __) => SizedBox(height: 30.h),
              itemBuilder: (context, index) {
                final comm = _myCommunities[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, comm);
                  },
                  child: Container(
                    padding: EdgeInsets.all(30.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 60.r,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (comm['icon_url'] != null && comm['icon_url'] != "")
                              ? CachedNetworkImageProvider(comm['icon_url'])
                              : null,
                          child: (comm['icon_url'] == null || comm['icon_url'] == "")
                              ? Icon(Icons.groups, color: Colors.grey, size: 60.sp)
                              : null,
                        ),
                        SizedBox(width: 40.w),
                        Expanded(
                          child: Text(
                            comm['name'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40.sp),
                          ),
                        ),
                        Icon(Icons.check_circle_outline, color: Colors.blue, size: 60.sp),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
