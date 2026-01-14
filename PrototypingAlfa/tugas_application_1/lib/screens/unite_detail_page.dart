import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import '../widgets/unite_item.dart';

class UniteDetailPage extends StatefulWidget {
  final Map uniteMessage; // Pesan Induk
  final int currentUserId;
  final int communityOwnerId; // Buat izin hapus

  const UniteDetailPage({
    super.key,
    required this.uniteMessage,
    required this.currentUserId,
    required this.communityOwnerId,
  });

  @override
  State<UniteDetailPage> createState() => _UniteDetailPageState();
}

class _UniteDetailPageState extends State<UniteDetailPage> {
  List _replies = [];
  bool _isLoading = true;
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  // AMBIL DATA REPLY DARI BACKEND
  Future<void> _fetchReplies() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseUrl}/get_unite_replies?message_id=${widget.uniteMessage['id']}"),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _replies = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching replies: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // KIRIM REPLY
  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/send_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "community_id": widget.uniteMessage['community_id'], // Masih di komunitas yang sama
          "user_id": widget.currentUserId,
          "content": _replyController.text,
          "parent_id": widget.uniteMessage['id'], // 🔥 INI KUNCINYA: Nempel ke Induk
        }),
      );

      if (response.statusCode == 201) {
        _replyController.clear();
        _fetchReplies(); // Refresh list reply
      }
    } catch (e) {
      print("Error sending reply: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  // HAPUS REPLY
  Future<void> _deleteReply(int messageId) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/delete_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message_id": messageId, "user_id": widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        _fetchReplies();
      }
    } catch (e) {
      print("Error deleting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 50.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Unite",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. INDUK UNITE (Main Post)
                  // Kita tampilin garis pemisah biar keliatan bedanya
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 2.h),
                      ),
                    ),
                    child: UniteItem(
                      message: widget.uniteMessage,
                      currentUserId: widget.currentUserId,
                      communityOwnerId: widget.communityOwnerId,
                      onDelete: (id) => Navigator.pop(context), // Kalau induk dihapus, balik
                      disableTap: true, // 🔥 Biar gak loop (diklik gak buka detail lagi)
                    ),
                  ),

                  // 2. LIST REPLY
                  if (_isLoading)
                    Padding(padding: EdgeInsets.all(50.h), child: const CircularProgressIndicator())
                  else if (_replies.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(100.h),
                      child: Text(
                        "No replies yet. Be the first!",
                        style: TextStyle(color: Colors.grey, fontSize: 35.sp),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _replies.length,
                      itemBuilder: (context, index) {
                        final reply = _replies[index];
                        return UniteItem(
                          message: reply,
                          currentUserId: widget.currentUserId,
                          communityOwnerId: widget.communityOwnerId,
                          onDelete: _deleteReply,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // 3. INPUT REPLY BAR
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(50.r)),
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(fontSize: 35.sp),
                      decoration: InputDecoration(
                        hintText: "Reply to Unite...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 30.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: _isSending ? null : _sendReply,
                  child: CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.blue,
                    child: _isSending
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w)
                        : Icon(Icons.send, color: Colors.white, size: 40.sp),
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
