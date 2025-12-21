import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class PostItem extends StatefulWidget {
  final Map post;
  final int currentUserId;
  final Function(bool isLiked, int newCount)? onLikeChanged;

  // 🔥 TAMBAHAN BARU: CALLBACK SAVE 🔥
  final Function(bool isSaved)? onSaveChanged;

  const PostItem({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onLikeChanged,
    this.onSaveChanged, // 🔥 JANGAN LUPA INI
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool isLiked = false;
  int totalLikes = 0;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post['is_liked'] ?? false;
    totalLikes = widget.post['total_likes'] ?? 0;
    isSaved = widget.post['is_saved'] ?? false;
  }

  Future<void> _toggleLike() async {
    bool oldStatus = isLiked;
    int oldTotal = totalLikes;

    setState(() {
      isLiked = !isLiked;
      totalLikes = isLiked ? totalLikes + 1 : totalLikes - 1;
    });

    if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(isLiked, totalLikes);
    }

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_like"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.currentUserId, "post_id": widget.post['id']}),
      );
      if (response.statusCode != 200) {
        setState(() {
          isLiked = oldStatus;
          totalLikes = oldTotal;
        });
      }
    } catch (e) {
      print("Error like: $e");
      setState(() {
        isLiked = oldStatus;
        totalLikes = oldTotal;
      });
    }
  }

  Future<void> _toggleSave() async {
    bool oldStatus = isSaved;
    setState(() {
      isSaved = !isSaved;
    });

    // 🔥 LAPOR KE HOME PAGE KALAU STATUS BERUBAH 🔥
    if (widget.onSaveChanged != null) {
      widget.onSaveChanged!(isSaved);
    }

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/toggle_save"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.currentUserId, "post_id": widget.post['id']}),
      );
      if (response.statusCode != 200) {
        setState(() => isSaved = oldStatus);

        // Kalau gagal, lapor balik status lama
        if (widget.onSaveChanged != null) {
          widget.onSaveChanged!(oldStatus);
        }
        print("Gagal save: ${response.body}");
      }
    } catch (e) {
      print("Error save: $e");
      setState(() => isSaved = oldStatus);
      // Kalau error, lapor balik status lama
      if (widget.onSaveChanged != null) {
        widget.onSaveChanged!(oldStatus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 SAFETY CHECK: Kalau username null, ganti jadi "User" biar gak error
    String safeUsername = widget.post['username'] ?? "User";
    String safeInitial = safeUsername.isNotEmpty ? safeUsername[0] : "U";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                child: widget.post['profile_pic_url'] != null && widget.post['profile_pic_url'] != ""
                    ? ClipOval(
                        child: Image.network(
                          widget.post['profile_pic_url'],
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (ctx, _, __) =>
                              Text(safeInitial.toUpperCase(), style: const TextStyle(fontSize: 35)),
                        ),
                      )
                    : Text(
                        safeInitial.toUpperCase(), // 🔥 PAKE INITIAL YANG AMAN
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 35),
                      ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        safeUsername, // 🔥 PAKE USERNAME YANG AMAN
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 45),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 35),
                    ],
                  ),
                  if (widget.post['location_name'] != null && widget.post['location_name'] != "")
                    Text(widget.post['location_name'], style: const TextStyle(fontSize: 32, color: Colors.black54)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.black, size: 60),
            ],
          ),
        ),

        // --- 2. GAMBAR UTAMA ---
        SizedBox(
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(
              widget.post['image_url'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200),
            ),
          ),
        ),

        // --- 3. ACTION BAR ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.black,
                  size: 80,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.chat_bubble_outline, size: 80),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSave,
                child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.black, size: 80),
              ),
            ],
          ),
        ),

        // --- 4. CAPTION & STATS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$totalLikes suka", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 32),
                  children: [
                    TextSpan(
                      text: "$safeUsername ", // 🔥 PAKE USERNAME YANG AMAN
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // 🔥 SAFETY JUGA BUAT CAPTION KALO NULL
                    TextSpan(text: widget.post['caption'] ?? ""),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.post['created_at'] ?? "", style: const TextStyle(fontSize: 25, color: Colors.grey)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
