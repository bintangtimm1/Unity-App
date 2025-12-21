import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../widgets/post_item.dart'; // Import Widget PostItem yang baru dibuat

class HomePage extends StatefulWidget {
  final String username;
  final int userId;

  const HomePage({super.key, required this.username, required this.userId});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  // --- AMBIL DATA DARI SERVER ---
  // --- AMBIL DATA DARI SERVER ---
  Future<void> fetchPosts() async {
    try {
      // 🔥 TAMBAHAN: Kirim ID User lewat URL (?user_id=...)
      // Biar server tau siapa yang lagi minta data
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_posts?user_id=${widget.userId}"));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _posts = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        print("Gagal ambil post: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetch posts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // --- 1. HEADER CUSTOM (Sesuai home page.txt) ---
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1080,
                  height: 290, // Tinggi Header
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2), // Bayangan halus
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    // Gambar Header Custom Kamu
                    child: Image.asset('assets/images/Header_Home_Page.png', fit: BoxFit.fill),
                  ),
                ),

                // --- 2. KONTEN POSTINGAN (Menggantikan Profile Info) ---
                Positioned(
                  left: 0,
                  top: 290, // Mulai tepat di bawah Header (290px)
                  width: 1080,
                  bottom: 0, // Memanjang sampai bawah layar
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: fetchPosts, // Tarik buat refresh
                          color: Colors.black,
                          child: _posts.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image_not_supported_outlined, size: 150, color: Colors.grey),
                                    const SizedBox(height: 40),
                                    const Text(
                                      "Belum ada postingan.",
                                      style: TextStyle(fontSize: 40, color: Colors.grey),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  // Kasih padding top dikit & padding bawah GEDE biar gak ketutup Navbar
                                  padding: const EdgeInsets.only(top: 20, bottom: 250),
                                  itemCount: _posts.length,
                                  itemBuilder: (context, index) {
                                    return PostItem(
                                      post: _posts[index],
                                      currentUserId: widget.userId,

                                      // Update Like (Yang lama)
                                      onLikeChanged: (bool isLiked, int newCount) {
                                        _posts[index]['is_liked'] = isLiked;
                                        _posts[index]['total_likes'] = newCount;
                                      },

                                      // 🔥 UPDATE SAVE (YANG BARU) 🔥
                                      onSaveChanged: (bool isSaved) {
                                        // Kita update data di memori list _posts
                                        // Jadi pas discroll balik, dia baca data yang udah TRUE
                                        _posts[index]['is_saved'] = isSaved;
                                      },
                                    );
                                  },
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
