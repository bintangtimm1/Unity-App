import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../widgets/approval_item.dart';

class CommunityApprovalPage extends StatefulWidget {
  final int communityId;
  final int currentUserId;

  const CommunityApprovalPage({super.key, required this.communityId, required this.currentUserId});

  @override
  State<CommunityApprovalPage> createState() => _CommunityApprovalPageState();
}

class _CommunityApprovalPageState extends State<CommunityApprovalPage> {
  List _pendingPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingPosts();
  }

  // --- 1. FETCH DATA DARI BACKEND ---
  Future<void> _fetchPendingPosts() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${Config.baseUrl}/get_community_pending_posts?community_id=${widget.communityId}&user_id=${widget.currentUserId}",
        ),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pendingPosts = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. FUNGSI EKSEKUSI APPROVE / REJECT ---
  Future<void> _handleAction(int postId, String action) async {
    // Optimistic Update: Hapus dulu dari UI biar terasa cepat
    setState(() {
      _pendingPosts.removeWhere((item) => item['id'] == postId);
    });

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/manage_community_post"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.currentUserId,
          "post_id": postId,
          "action": action, // 'approve' atau 'reject'
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve' ? "Post Approved!" : "Post Declined!"),
            duration: const Duration(seconds: 1),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
      } else {
        // Kalau gagal, refresh data biar muncul lagi
        _fetchPendingPosts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action failed!")));
      }
    } catch (e) {
      print("Error action: $e");
      _fetchPendingPosts();
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
          child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 50.sp),
        ),
        title: Text(
          "Approval",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 150.sp, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Text(
                    "No pending approvals",
                    style: TextStyle(fontSize: 34.sp, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _pendingPosts.length,
              itemBuilder: (context, index) {
                final post = _pendingPosts[index];
                return ApprovalItem(
                  postData: post,
                  currentUserId: widget.currentUserId,
                  onApprove: (id) => _handleAction(id, 'approve'),
                  onReject: (id) => _handleAction(id, 'reject'),
                );
              },
            ),
    );
  }
}
