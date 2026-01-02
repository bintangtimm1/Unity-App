import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'comment_item.dart';

class CommentSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;

  const CommentSheet({super.key, required this.postId, required this.currentUserId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  // 🔥 POSISI HALTE 🔥
  final double _fullHeight = 0.93; // Mode Full
  final double _midHeight = 0.7; // Mode Baca
  final double _closeThreshold = 0.5; // Batas Tutup

  late double _currentHeight;

  @override
  void initState() {
    super.initState();
    _currentHeight = _midHeight; // Start di 0.7
    _fetchComments();

    // Logic: Kalau Ngetik -> Naik Full
    _focusNode.addListener(() {
      if (mounted && _focusNode.hasFocus) {
        setState(() => _currentHeight = _fullHeight);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_comments?post_id=${widget.postId}"));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _comments = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/add_comment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.currentUserId,
          "post_id": widget.postId,
          "comment_text": _commentController.text,
        }),
      );
      if (response.statusCode == 201) {
        _commentController.clear();
        _fetchComments();
        // Jangan tutup keyboard biar bisa spam komen kalau mau
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/delete_comment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"comment_id": commentId, "user_id": widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        _fetchComments();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comment deleted.")));
      }
    } catch (e) {
      print("Error delete: $e");
    }
  }

  // 🔥 LOGIC INTI: UPDATE TINGGI SHEET 🔥
  void _updateHeight(double deltaDy) {
    // Kalau keyboard lagi buka, tutup dulu
    if (_focusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      // Kurangi tinggi sesuai gerakan jari
      _currentHeight -= deltaDy / 1.sh;
    });
  }

  // 🔥 LOGIC INTI: LEPAS JARI (SNAP) 🔥
  void _snapHeight() {
    setState(() {
      // 1. Kalau di atas 0.8 -> Full (0.93)
      if (_currentHeight > 0.8) {
        _currentHeight = _fullHeight;
      }
      // 2. Kalau di antara 0.5 s/d 0.8 -> Tengah (0.7)
      else if (_currentHeight > _closeThreshold) {
        _currentHeight = _midHeight;
      }
      // 3. Kalau di bawah 0.5 -> TUTUP
      else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150), // Animasi responsif cepat
      curve: Curves.easeOut,
      height: _currentHeight.sh,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(80.r)),
      ),

      child: Column(
        children: [
          // --- HEADER (DRAGGABLE) ---
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) => _updateHeight(details.delta.dy),
            onVerticalDragEnd: (_) => _snapHeight(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 10.h),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  Container(
                    width: 100.w,
                    height: 10.h,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Comments",
                    style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),

          Divider(thickness: 2.h, color: Colors.grey.shade200, height: 0),

          // --- LIST KOMEN (DRAGGABLE SAAT DI TOP) ---
          Expanded(
            // 🔥 LISTENER BIAR LIST JUGA BISA BUAT NARIK SHEET 🔥
            child: Listener(
              onPointerMove: (event) {
                // Cek: Apakah jari gerak ke BAWAH (dy > 0) DAN List lagi mentok ATAS?
                bool isAtTop = !_scrollController.hasClients || _scrollController.offset <= 0;

                if (isAtTop && event.delta.dy > 0) {
                  // Hijack scroll list -> Jadi resize sheet
                  _updateHeight(event.delta.dy);
                }
              },
              onPointerUp: (_) {
                // Pas jari dilepas, cek mau snap kemana
                bool isAtTop = !_scrollController.hasClients || _scrollController.offset <= 0;
                if (isAtTop) {
                  _snapHeight();
                }
              },

              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  // Logic tutup keyboard kalau scroll ke atas (jari turun) dalam list
                  if (_focusNode.hasFocus && notification.scrollDelta != null) {
                    if (notification.scrollDelta! < -1.0) {
                      FocusScope.of(context).unfocus();
                    }
                  }
                  return false;
                },
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "No comments yet",
                              style: TextStyle(fontSize: 45.sp, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 0.h),
                            Text(
                              "Be the first to comment.",
                              style: TextStyle(fontSize: 35.sp, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(), // Wajib Bouncing biar enak
                        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return CommentItem(
                            comment: _comments[index],
                            currentUserId: widget.currentUserId,
                            onDelete: (id) => _deleteComment(id),
                          );
                        },
                      ),
              ),
            ),
          ),

          // --- INPUT FIELD ---
          Container(
            padding: EdgeInsets.only(
              left: 40.w,
              right: 40.w,
              top: 25.h,
              bottom: isKeyboardOpen ? keyboardHeight + 40.h : 50.h + safeAreaBottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 2.h),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 15.h),
                  child: CircleAvatar(
                    radius: 45.r,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(Icons.person, color: Colors.grey, size: 50.sp),
                  ),
                ),
                SizedBox(width: 30.w),

                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 250.h),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,

                      style: TextStyle(fontSize: 35.sp),
                      decoration: InputDecoration(
                        hintText: "Add comment...",
                        hintStyle: TextStyle(fontSize: 35.sp, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 35.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),

                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: IconButton(
                    onPressed: _isSending ? null : _postComment,
                    icon: _isSending
                        ? SizedBox(width: 50.w, height: 50.w, child: const CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send, color: Colors.blue, size: 65.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
