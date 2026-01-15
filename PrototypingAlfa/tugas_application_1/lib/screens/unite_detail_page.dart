import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 1. WAJIB IMPORT INI BUAT MAKSA KEYBOARD
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';
import '../widgets/unite_item.dart';
import '../widgets/verification_badge.dart';
import '../widgets/unite_menu_sheet.dart';
import 'unite_reply_page.dart';

class UniteDetailPage extends StatefulWidget {
  final Map uniteMessage;
  final int currentUserId;
  final int communityOwnerId;

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

  // 🔥 2. BUAT FOCUS NODE KHUSUS
  final FocusNode _replyFocusNode = FocusNode();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose(); // 🔥 JANGAN LUPA DISPOSE
    super.dispose();
  }

  String _formatXDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      String minute = date.minute.toString().padLeft(2, '0');
      String period = date.hour >= 12 ? "PM" : "AM";
      String day = date.day.toString();
      String month = date.month.toString();
      String year = date.year.toString().substring(2);
      return "$hour.$minute$period • $month/$day/$year";
    } catch (e) {
      return "";
    }
  }

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

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/send_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "community_id": widget.uniteMessage['community_id'],
          "user_id": widget.currentUserId,
          "content": _replyController.text,
          "parent_id": widget.uniteMessage['id'],
        }),
      );

      if (response.statusCode == 201) {
        _replyFocusNode.unfocus(); // Cabut fokus
        _replyController.clear();
        _fetchReplies();
      }
    } catch (e) {
      print("Error sending reply: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _deleteReply(int messageId) async {
    setState(() {
      _replies.removeWhere((item) => item['id'] == messageId);
    });

    try {
      // 2. Kirim request hapus ke server di background
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/delete_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message_id": messageId, "user_id": widget.currentUserId}),
      );

      // 3. Kalau ternyata gagal di server, kita refresh list biar balik lagi
      if (response.statusCode != 200) {
        _fetchReplies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus pesan")));
        }
      }
    } catch (e) {
      print("Error deleting: $e");
      // Kalau error koneksi, refresh list biar sinkron
      _fetchReplies();
    }
  }

  void _showMainMenu() {
    int msgId = widget.uniteMessage['id'];
    int authorId = int.tryParse(widget.uniteMessage['user_id'].toString()) ?? 0;
    bool isOwner = (widget.currentUserId == widget.communityOwnerId);
    bool isAuthor = (widget.currentUserId == authorId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UniteMenuSheet(
        message: widget.uniteMessage,
        isOwner: isOwner,
        isAuthor: isAuthor,
        currentUserId: widget.currentUserId,
        onDelete: () async {
          try {
            final response = await http.post(
              Uri.parse("${Config.baseUrl}/delete_community_message"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"message_id": msgId, "user_id": widget.currentUserId}),
            );
            if (response.statusCode == 200) {
              if (mounted) Navigator.pop(context);
            }
          } catch (e) {
            print("Error deleting main: $e");
          }
        },
      ),
    );
  }

  // 🔥 FUNGSI BUKA HALAMAN EXPAND (FORCE CLOSE KEYBOARD)
  void _openExpandedReply() async {
    // 1. Matikan Fokus Lokal Dulu
    _replyFocusNode.unfocus();

    String currentText = _replyController.text;

    // 2. Pindah Halaman
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniteReplyPage(
          parentMessage: widget.uniteMessage,
          currentUserId: widget.currentUserId,
          initialText: currentText,
        ),
      ),
    );

    // 3. SETELAH BALIK (SOLUSI FINAL)
    if (mounted) {
      // A. Bersihkan Teks
      _replyController.clear();

      // B. Cabut Fokus dari Node
      _replyFocusNode.unfocus();

      // C. Fokus ke Node Kosong (Biar fokus lepas total)
      FocusScope.of(context).requestFocus(FocusNode());

      // D. 🔥 PERINTAH OS: SEMBUNYIKAN KEYBOARD SEKARANG JUGA!
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }

    if (success == true) {
      _fetchReplies();
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.uniteMessage['display_name'] ?? widget.uniteMessage['username'] ?? "User";
    String handle = "@" + (widget.uniteMessage['username'] ?? "user");
    String avatarUrl = widget.uniteMessage['avatar_url'] ?? "";
    String content = widget.uniteMessage['content'] ?? "";
    String tier = widget.uniteMessage['tier'] ?? 'regular';
    String timeString = _formatXDate(widget.uniteMessage['created_at']);

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
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black, size: 50.sp),
            onPressed: _showMainMenu,
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- DETAIL MAIN POST ---
                  Container(
                    padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 2.h),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 65.r,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                              child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.grey, size: 65.sp) : null,
                            ),
                            SizedBox(width: 30.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      displayName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 42.sp),
                                    ),
                                    SizedBox(width: 10.w),
                                    if (tier != 'regular') VerificationBadge(tier: tier, size: 40.sp),
                                  ],
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  handle,
                                  style: TextStyle(color: Colors.grey, fontSize: 36.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 30.h),
                        Text(
                          content,
                          style: TextStyle(fontSize: 40.sp, color: Colors.black87, height: 1.3),
                        ),
                        SizedBox(height: 30.h),
                        Divider(color: Colors.grey.shade300, thickness: 2.h),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 50.sp, color: Colors.black),
                            SizedBox(width: 40.w),
                            Icon(Icons.favorite_border, size: 50.sp, color: Colors.black),
                            const Spacer(),
                            Text(
                              timeString,
                              style: TextStyle(fontSize: 32.sp, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),

                  // --- LIST REPLIES ---
                  if (_isLoading)
                    Padding(padding: EdgeInsets.all(50.h), child: const CircularProgressIndicator())
                  else if (_replies.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(100.h),
                      child: Text(
                        "No replies yet.",
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

          // 4. INPUT REPLY BAR
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(30.w, 20.h, 30.w, 50.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(50.r)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              focusNode: _replyFocusNode, // 🔥 3. PASANG FOCUS NODE DI SINI
                              style: TextStyle(fontSize: 35.sp),
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText: "Reply to Unite...",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 30.h),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: _openExpandedReply,
                            child: Icon(Icons.open_in_full_rounded, color: Colors.grey, size: 40.sp),
                          ),
                        ],
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
          ),
        ],
      ),
    );
  }
}
