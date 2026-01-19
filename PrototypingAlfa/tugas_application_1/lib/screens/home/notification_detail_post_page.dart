import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config.dart';
import '../../widgets/post_item.dart';
import '../../widgets/comment_item.dart'; // Jangan lupa import CommentItem

class NotificationDetailPostPage extends StatefulWidget {
  final int postId;
  final int currentUserId;

  const NotificationDetailPostPage({super.key, required this.postId, required this.currentUserId});

  @override
  State<NotificationDetailPostPage> createState() => _NotificationDetailPostPageState();
}

class _NotificationDetailPostPageState extends State<NotificationDetailPostPage> {
  Map? _postData;
  List _comments = [];
  bool _isLoadingPost = true;
  bool _isLoadingComments = true;

  // Controller buat scroll
  late ScrollController _scrollController;

  // Key buat nandain lokasi "Judul Komentar" biar bisa di-target
  final GlobalKey _commentSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchPostDetail();
    _fetchComments();
  }

  // 1. Ambil Data Post
  Future<void> _fetchPostDetail() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/get_single_post?post_id=${widget.postId}&user_id=${widget.currentUserId}"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _postData = jsonDecode(response.body);
          _isLoadingPost = false;
        });
      } else {
        // 🔥 INI OBATNYA: Kalau gagal (500/404), stop loading!
        print("Gagal load post: ${response.statusCode}");
        setState(() {
          _isLoadingPost = false;
        });
      }
    } catch (e) {
      print("Error fetching post: $e");
      // 🔥 INI JUGA: Kalau internet mati, stop loading!
      setState(() => _isLoadingPost = false);
    }
  }

  // 2. Ambil Data Komentar
  Future<void> _fetchComments() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_comments?post_id=${widget.postId}"));
      if (response.statusCode == 200) {
        setState(() {
          _comments = jsonDecode(response.body);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print("Error fetching comments: $e");
      setState(() => _isLoadingComments = false);
    }
  }

  void _scrollToComments() {
    // Pastikan widgetnya udah ngerender
    if (_commentSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _commentSectionKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.0, // 0.0 artinya align ke atas layar (Top)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // 🔥 1. Biar warna GAK BERUBAH pas scroll
        scrolledUnderElevation: 0, // 🔥 2. Hapus efek bayangan otomatis
        elevation: 0,
        centerTitle: true,

        // 🔥 3. GARIS PEMBATAS TIPIS
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200, // Warna garisnya
            height: 1.0,
          ),
        ),

        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 60.sp),
        ),
        title: Text(
          "Details",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingPost
          ? const Center(child: CircularProgressIndicator())
          : _postData == null
          ? const Center(child: Text("Postingan tidak ditemukan"))
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                // --- A. POSTINGAN UTAMA ---
                SliverToBoxAdapter(
                  child: PostItem(
                    post: _postData!,
                    currentUserId: widget.currentUserId,
                    // 🔥 PASSING FUNGSI SCROLL KITA
                    onCommentTap: _scrollToComments,
                  ),
                ),

                // --- B. GARIS PEMBATAS & JUDUL ---
                SliverToBoxAdapter(
                  key: _commentSectionKey, // 🚩 TANCAP BENDERA DISINI
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
                    ),
                    child: Text(
                      "Comments (${_comments.length})",
                      style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                  ),
                ),

                // --- C. LIST KOMENTAR ---
                _isLoadingComments
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
                        ),
                      )
                    : _comments.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(50.h),
                          child: Center(
                            child: Text(
                              "Belum ada komentar",
                              style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 30.sp),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: CommentItem(
                              comment: _comments[index],
                              currentUserId: widget.currentUserId,
                              onDelete: (id) async {
                                // Logic hapus kalau mau dipasang juga (opsional)
                              },
                            ),
                          );
                        }, childCount: _comments.length),
                      ),

                // SPASI BAWAH
                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
    );
  }
}
