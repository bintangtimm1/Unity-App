import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🔥 IMPORT PENTING (Sesuaikan jumlah titik ../ dengan folder kamu)
import '../config.dart';
import '../widgets/post_item.dart';

class SearchPostDetailPage extends StatefulWidget {
  final int postId;
  final int currentUserId;

  const SearchPostDetailPage({super.key, required this.postId, required this.currentUserId});

  @override
  State<SearchPostDetailPage> createState() => _SearchPostDetailPageState();
}

class _SearchPostDetailPageState extends State<SearchPostDetailPage> {
  // Kita pakai List biar formatnya sama persis kayak Home Page
  List _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
  }

  // Ambil data post spesifik, lalu masukkan ke dalam List
  Future<void> _fetchPostDetail() async {
    try {
      // 🔥 UPDATE URL: TAMBAHKAN &user_id=${widget.currentUserId}
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/get_post_detail?post_id=${widget.postId}&user_id=${widget.currentUserId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _posts = [data];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetch post: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR STANDAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Explore",
          style: TextStyle(color: Colors.black, fontSize: 34.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // 🔥 BODY: LISTVIEW (MIRIP HOME PAGE)
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? Center(child: Text("Post not found"))
          : ListView.builder(
              padding: EdgeInsets.only(top: 10.h, bottom: 50.h),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                // 🔥 PANGGIL WIDGET POST_ITEM (Sama kayak di Home)
                return PostItem(
                  post: _posts[index],
                  currentUserId: widget.currentUserId,

                  // Logic Update Like (Biar tombolnya berubah warna pas diklik)
                  onLikeChanged: (bool isLiked, int newCount) {
                    setState(() {
                      _posts[index]['is_liked'] = isLiked;
                      _posts[index]['total_likes'] = newCount;
                    });
                  },

                  // Logic Update Save
                  onSaveChanged: (bool isSaved) {
                    setState(() {
                      _posts[index]['is_saved'] = isSaved;
                    });
                  },

                  // Navigasi kalau foto profil diklik (Balik ke profile atau visit)
                  onNavigateToProfileTab: () {
                    // Opsional: Bisa diisi navigasi ke profile
                  },
                );
              },
            ),
    );
  }
}
