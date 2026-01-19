import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config.dart';

class CreateUnitePage extends StatefulWidget {
  final int communityId;
  final int currentUserId;

  const CreateUnitePage({super.key, required this.communityId, required this.currentUserId});

  @override
  State<CreateUnitePage> createState() => _CreateUnitePageState();
}

class _CreateUnitePageState extends State<CreateUnitePage> {
  final TextEditingController _textController = TextEditingController();
  bool _isPosting = false;

  // 🔥 FUNGSI POSTING PESAN
  Future<void> _postMessage() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/send_community_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "community_id": widget.communityId,
          "user_id": widget.currentUserId,
          "content": _textController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to post message")));
      }
    } catch (e) {
      print("Error posting unite: $e");
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 50.sp), // Icon Close/Back
        ),
        title: Text(
          "Add Unite",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          // TOMBOL POST
          Padding(
            padding: EdgeInsets.only(right: 30.w),
            child: TextButton(
              onPressed: _isPosting ? null : _postMessage,
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 0),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 30.w,
                      height: 30.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      "Post",
                      style: TextStyle(color: Colors.blue, fontSize: 40.sp, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          children: [
            // KOLOM INPUT TEXT
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true, // Langsung muncul keyboard
                maxLines: null, // Bisa enter banyak baris
                style: TextStyle(fontSize: 36.sp, color: Colors.black),
                decoration: InputDecoration(
                  hintText: "What's happening in this community?",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 36.sp),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
