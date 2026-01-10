import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/caption_editor_page.dart';
import 'tag_search_page.dart';
import 'location_search_page.dart'; // 🔥 1. IMPORT SEARCH PAGE
import '../config.dart';
import 'main_screen.dart';
import 'community_selection_page.dart';

class PostUploadPage extends StatefulWidget {
  final File imageFile;
  final bool isSquareMode;
  final int userId;

  const PostUploadPage({super.key, required this.imageFile, required this.isSquareMode, required this.userId});

  @override
  State<PostUploadPage> createState() => _PostUploadPageState();
}

class _PostUploadPageState extends State<PostUploadPage> {
  String _captionText = "";
  List<UserStub> _taggedUsers = [];
  String? _selectedLocation;
  Map<String, dynamic>? _selectedCommunity;
  bool _isUploading = false;

  // --- FUNGSI UPLOAD ---
  Future<void> _uploadPost() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      var uri = Uri.parse("${Config.baseUrl}/create_post");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = widget.userId.toString();
      request.fields['caption'] = _captionText;
      request.fields['location'] = _selectedLocation ?? "";
      request.fields['is_square'] = widget.isSquareMode.toString();
      request.fields['tagged_users'] = jsonEncode(_taggedUsers.map((u) => u.id).toList());

      // 🔥 KIRIM COMMUNITY ID (Kalau ada yang dipilih)
      if (_selectedCommunity != null) {
        request.fields['community_id'] = _selectedCommunity!['id'].toString();
      } else {
        request.fields['community_id'] = ""; // Kirim string kosong biar backend tau
      }

      var pic = await http.MultipartFile.fromPath("image", widget.imageFile.path);
      request.files.add(pic);

      var response = await request.send();

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(userId: widget.userId, username: "User"),
            ),
            (route) => false,
          );
        }
      } else {
        print("Gagal Upload: ${response.statusCode}");
      }
    } catch (e) {
      print("Error Upload: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openCaptionEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CaptionEditorPage(initialText: _captionText)),
    );
    if (result != null && result is String) setState(() => _captionText = result);
  }

  void _openTagSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TagSearchPage(alreadyTagged: _taggedUsers)),
    );
    if (result != null && result is List<UserStub>) setState(() => _taggedUsers = result);
  }

  void _openCommunitySelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunitySelectionPage(
          userId: widget.userId,
          selectedCommunityId: _selectedCommunity?['id'], // Kirim ID lama biar kecentang
        ),
      ),
    );

    // 🔥 LOGIKA BARU ANTI-BUG:
    // Kita cek apakah ada kunci 'confirm'.
    if (result != null && result is Map && result['confirm'] == true) {
      setState(() {
        // Update data (bisa jadi NULL kalau di-uncheck, dan itu BENAR)
        _selectedCommunity = result['data'];
      });
    }
    // Kalau result null (User tekan Back), kita diamkan saja (gak ngerubah apa-apa).
  }

  // 🔥 4. FUNGSI BUKA SEARCH LOCATION
  void _openLocationSearch() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSearchPage()));

    // Kalau user milih kota (result tidak null)
    if (result != null && result is String) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            // --- HEADER FIXED ---
            Positioned(
              left: 0,
              top: 0,
              width: 1.sw,
              height: 290.h,
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned(
                      left: 40.w,
                      bottom: 40.h,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios, size: 60.sp),
                      ),
                    ),
                    Positioned(
                      bottom: 50.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          "New Post",
                          style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 60.w,
                      bottom: 50.h,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _uploadPost,
                        child: _isUploading
                            ? const CircularProgressIndicator()
                            : Text(
                                "Share",
                                style: TextStyle(fontSize: 35.sp, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- KONTEN SCROLLABLE ---
            Positioned(
              top: 320.h,
              left: 0,
              width: 1.sw,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PREVIEW IMAGE
                    Container(
                      width: 1.sw,
                      height: widget.isSquareMode ? 1.sw : 1.25.sw,
                      color: Colors.white,
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),

                    SizedBox(height: 50.h),

                    // CAPTION INPUT
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50.w),
                      child: GestureDetector(
                        onTap: _openCaptionEditor,
                        child: Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          constraints: BoxConstraints(minHeight: 100.h),
                          child: Text(
                            _captionText.isEmpty ? "Write a caption..." : _captionText,
                            style: TextStyle(fontSize: 32.sp, color: _captionText.isEmpty ? Colors.grey : Colors.black),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 50.h),

                    // MENU ITEMS
                    _buildMenuItem("Tag People", Icons.person_outline, onTap: _openTagSearch),

                    // 🔥 MENU LOCATION SUDAH INTERAKTIF
                    _buildMenuItem(
                      _selectedCommunity != null
                          ? _selectedCommunity!['name']
                          : "Tag Community", // Kalau dipilih, ganti teks jadi nama community
                      Icons.groups_outlined, // Icon Community
                      onTap: _openCommunitySelection,
                      isActive: _selectedCommunity != null, // Warna biru kalau aktif
                    ),
                    _buildMenuItem(
                      _selectedLocation ?? "Add Location", // Tampilkan kota kalau sudah dipilih
                      Icons.location_on_outlined,
                      onTap: _openLocationSearch,
                      isActive: _selectedLocation != null, // Ubah warna kalau sudah dipilih
                    ),

                    _buildMenuItem("Add Music", Icons.music_note_outlined),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATE WIDGET MENU BIAR BISA BERUBAH WARNA
  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 1.sw,
        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 2.h),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 50.sp,
              color: isActive ? Colors.blue : Colors.black, // Ikon jadi biru kalau aktif
            ),
            SizedBox(width: 30.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.blue : Colors.black, // Teks jadi biru kalau aktif
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isActive) // Hilangkan panah kalau sudah ada isinya (opsional, biar bersih)
              Icon(Icons.chevron_right, size: 50.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
