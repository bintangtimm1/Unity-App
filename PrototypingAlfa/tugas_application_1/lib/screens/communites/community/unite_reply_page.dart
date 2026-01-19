import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../config.dart';
import '../../../widgets/verification_badge.dart';

class UniteReplyPage extends StatefulWidget {
  final Map parentMessage;
  final int currentUserId;
  final String? initialText; // 🔥 1. TERIMA TEKS DARI HALAMAN SEBELUMNYA

  const UniteReplyPage({super.key, required this.parentMessage, required this.currentUserId, this.initialText});

  @override
  State<UniteReplyPage> createState() => _UniteReplyPageState();
}

class _UniteReplyPageState extends State<UniteReplyPage> {
  late TextEditingController _replyController; // 🔥 2. LATE INIT
  bool _isSending = false;
  String _myAvatarUrl = "";

  @override
  void initState() {
    super.initState();
    // 🔥 3. ISI CONTROLLER DENGAN INITIAL TEXT
    _replyController = TextEditingController(text: widget.initialText ?? "");
    _fetchMyAvatar();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyAvatar() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Config.baseUrl}/get_profile_info?user_id=${widget.currentUserId}&visitor_id=${widget.currentUserId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _myAvatarUrl = data['avatar_url'] ?? "");
      }
    } catch (e) {}
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/send_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "community_id": widget.parentMessage['community_id'],
          "user_id": widget.currentUserId,
          "content": _replyController.text,
          "parent_id": widget.parentMessage['id'],
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true); // Kirim sinyal SUKSES
      }
    } catch (e) {
      print("Error reply: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String pName = widget.parentMessage['display_name'] ?? widget.parentMessage['username'] ?? "User";
    String pHandle = "@" + (widget.parentMessage['username'] ?? "user");
    String pAvatar = widget.parentMessage['avatar_url'] ?? "";
    String pContent = widget.parentMessage['content'] ?? "";
    String pTier = widget.parentMessage['tier'] ?? 'regular';
    String pTime = "";
    try {
      pTime = timeago.format(DateTime.parse(widget.parentMessage['created_at']), locale: 'en_short');
    } catch (e) {
      pTime = "now";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 200.w,
        leading: TextButton(
          onPressed: () => Navigator.pop(context), // Balik tanpa kirim (Cancel)
          child: Text(
            "Back",
            style: TextStyle(
              color: const Color.fromARGB(255, 83, 83, 83),
              fontSize: 36.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                padding: EdgeInsets.symmetric(horizontal: 40.w),
              ),
              child: _isSending
                  ? SizedBox(
                      width: 30.w,
                      height: 30.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      "Post",
                      style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          children: [
            // PARENT MESSAGE
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 100.w,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: pAvatar.isNotEmpty ? CachedNetworkImageProvider(pAvatar) : null,
                        ),
                        Expanded(
                          child: Container(
                            width: 6.w,
                            color: const Color.fromARGB(255, 153, 153, 153),
                            margin: EdgeInsets.symmetric(vertical: 5.h),
                          ),
                        ),
                      ],
                    ),
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
                                pName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            if (pTier != 'regular') ...[
                              VerificationBadge(tier: pTier, size: 36.sp),
                              SizedBox(width: 10.w),
                            ],
                            Text(
                              "$pHandle · $pTime",
                              style: TextStyle(color: Colors.grey, fontSize: 32.sp),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Text(
                            pContent,
                            style: TextStyle(fontSize: 34.sp, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                          child: Row(
                            children: [
                              Text(
                                "Replying to ",
                                style: TextStyle(color: Colors.grey, fontSize: 32.sp),
                              ),
                              Text(
                                pHandle,
                                style: TextStyle(color: Colors.blue, fontSize: 32.sp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // USER REPLY INPUT
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100.w,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _myAvatarUrl.isNotEmpty ? CachedNetworkImageProvider(_myAvatarUrl) : null,
                        child: _myAvatarUrl.isEmpty ? Icon(Icons.person, color: Colors.grey) : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 30.w),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    autofocus: true,
                    maxLines: null,
                    style: TextStyle(fontSize: 34.sp),
                    decoration: InputDecoration(
                      hintText: "Post your reply",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 34.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 500.h),
          ],
        ),
      ),
    );
  }
}
