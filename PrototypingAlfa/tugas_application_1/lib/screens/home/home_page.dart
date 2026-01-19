import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config.dart';
import '../../widgets/post_item.dart';
import 'notification_page.dart';
import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;
  final VoidCallback onNavigateToProfileTab;

  const HomePage({super.key, required this.username, required this.userId, required this.onNavigateToProfileTab});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List _posts = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    fetchPosts();
    _fetchUnreadCount();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_posts?user_id=${widget.userId}"));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _posts = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/notifications/unread_count?user_id=${widget.userId}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _unreadCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Error fetching unread count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            // --- 1. HEADER CUSTOM ---
            Positioned(
              left: 0,
              top: 0,
              width: 1.sw,
              height: 290.h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15.r,
                      offset: Offset(0, 5.h),
                      spreadRadius: 5.r,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gambar Header Background
                    Positioned.fill(child: Image.asset('assets/images/Header_Home_Page.png', fit: BoxFit.fill)),

                    // 🔥 TOMBOL NOTIFIKASI (KIRI ATAS)
                    Positioned(
                      left: 50.w,
                      bottom: 40.h,
                      child: GestureDetector(
                        onTap: () async {
                          // Pas dipencet, buka halaman notif
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationPage(userId: widget.userId)),
                          );
                          // Pas balik dari halaman notif, refresh titik merah (pasti jadi 0)
                          _fetchUnreadCount();
                        },
                        child: Stack(
                          // Pakai Stack biar titiknya nindih icon
                          clipBehavior: Clip.none,
                          children: [
                            // 1. ICON LONCENG (Ganti dari favorite_border)
                            Icon(Icons.energy_savings_leaf_outlined, size: 75.sp, color: Colors.black),

                            // 2. TITIK MERAH (Hanya muncul kalau unread > 0)
                            if (_unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.w),
                                  // (Opsional) Kalau mau nampilin angka, uncomment text di bawah
                                  // child: Text('$_unreadCount', style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. KONTEN POSTINGAN ---
            Positioned(
              left: 0,
              top: 290.h,
              width: 1.sw,
              bottom: 0,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: fetchPosts,
                      color: Colors.black,
                      child: _posts.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 150.sp, color: Colors.grey),
                                SizedBox(height: 40.h),
                                Text(
                                  "Belum ada postingan.",
                                  style: TextStyle(fontSize: 40.sp, color: Colors.grey),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(top: 20.h, bottom: 250.h),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                return PostItem(
                                  post: _posts[index],
                                  currentUserId: widget.userId,
                                  onLikeChanged: (bool isLiked, int newCount) {
                                    _posts[index]['is_liked'] = isLiked;
                                    _posts[index]['total_likes'] = newCount;
                                  },
                                  onSaveChanged: (bool isSaved) {
                                    _posts[index]['is_saved'] = isSaved;
                                  },
                                  onNavigateToProfileTab: widget.onNavigateToProfileTab,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
