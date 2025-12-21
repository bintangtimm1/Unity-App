import 'package:flutter/material.dart';
import '../widgets/post_item.dart';

class DetailPostPage extends StatefulWidget {
  final String title;
  final String username;
  final List posts;
  final int initialIndex;
  final int currentUserId;

  const DetailPostPage({
    super.key,
    required this.title,
    required this.username,
    required this.posts,
    required this.initialIndex,
    required this.currentUserId,
  });

  @override
  State<DetailPostPage> createState() => _DetailPostPageState();
}

class _DetailPostPageState extends State<DetailPostPage> {
  late ScrollController _scrollController;
  late List _localPosts;

  @override
  void initState() {
    super.initState();
    _localPosts = widget.posts;

    if (widget.initialIndex > 0) {
      double estimatedOffset = widget.initialIndex * 1600.0;
      _scrollController = ScrollController(initialScrollOffset: estimatedOffset);
    } else {
      _scrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 ANGKA TUNING POSISI (GESER-GESER DISINI KING) 🔒

    // 1. Tinggi Header Keseluruhan
    const double headerHeight = 290.0; // Saya gedein dikit biar lega

    // 2. Posisi Tombol Back (Panah Kiri)
    const double backBtnTop = 160.0; // Jarak dari atas langit-langit
    const double backBtnLeft = 40.0; // Jarak dari tembok kiri

    // 3. Posisi Judul & Username (Teks Tengah)
    const double titleTop = 150.0; // Jarak dari atas (Turunin angka ini kalau kena kamera)
    const double userTop = 200;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1080,
            height: 2424,
            child: Stack(
              children: [
                // --- LAYER 1: LIST POSTINGAN ---
                Positioned.fill(
                  top: headerHeight,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: _localPosts.length,
                    itemBuilder: (context, index) {
                      return PostItem(
                        post: _localPosts[index],
                        currentUserId: widget.currentUserId,
                        onLikeChanged: (bool isLiked, int newCount) {
                          setState(() {
                            _localPosts[index]['is_liked'] = isLiked;
                            _localPosts[index]['total_likes'] = newCount;
                          });
                        },
                      );
                    },
                  ),
                ),

                // --- LAYER 2: CUSTOM HEADER (MANUAL POSITIONING) ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: headerHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    // KITA PAKE STACK BIAR BISA GESER BEBAS
                    child: Stack(
                      children: [
                        // A. TOMBOL BACK (PANAH)
                        Positioned(
                          top: backBtnTop,
                          left: backBtnLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 80),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),

                        // B. JUDUL & USERNAME (TENGAH)
                        Positioned(
                          top: titleTop,
                          left: 0,
                          right: 0, // Left 0 & Right 0 maksa dia di tengah (Center)
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.title, // "Creations" / "Saved"
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 40),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        Positioned(
                          top: userTop,
                          left: 0,
                          right: 0, // Left 0 & Right 0 maksa dia di tengah (Center)
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.username,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
