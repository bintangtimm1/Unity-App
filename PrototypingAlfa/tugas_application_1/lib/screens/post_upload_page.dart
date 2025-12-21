import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http; // Buat upload
import '../widgets/post_crop_preview.dart';
import '../widgets/caption_editor_page.dart';
import 'tag_search_page.dart';
import '../config.dart'; // File config base url

class PostUploadPage extends StatefulWidget {
  final AssetEntity entity;
  final bool isSquareMode;
  final Matrix4 cropMatrix;
  final int userId; // <--- WAJIB: ID User yang lagi login

  const PostUploadPage({
    super.key,
    required this.entity,
    required this.isSquareMode,
    required this.cropMatrix,
    required this.userId,
  });

  @override
  State<PostUploadPage> createState() => _PostUploadPageState();
}

class _PostUploadPageState extends State<PostUploadPage> {
  late TransformationController _readOnlyController;

  String _captionText = "";
  List<UserStub> _taggedUsers = [];
  bool _isUploading = false; // Loading status

  @override
  void initState() {
    super.initState();
    _readOnlyController = TransformationController(widget.cropMatrix);
  }

  // --- FUNGSI UPLOAD SAKTI ---
  // --- FUNGSI UPLOAD SAKTI (UPDATE: + LOCATION) ---
  Future<void> _uploadPost() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      File? imageFile = await widget.entity.file;
      if (imageFile == null) throw Exception("Gagal mengambil file gambar");

      var uri = Uri.parse("${Config.baseUrl}/create_post");
      var request = http.MultipartRequest("POST", uri);

      // 1. DATA DASAR
      request.fields['user_id'] = widget.userId.toString();
      request.fields['caption'] = _captionText; // <--- Server bakal ambil hashtag dari sini otomatis

      // 2. DATA LOKASI (DUMMY DULU)
      // Nanti kalau udah pake Google Maps, ini diambil dari variabel lokasi beneran
      request.fields['location'] = "Jakarta, Indonesia";

      // 3. DATA TAG PEOPLE
      List<int> tagIds = _taggedUsers.map((u) => u.id).toList();
      request.fields['tagged_users'] = jsonEncode(tagIds);

      // 4. FILE GAMBAR
      var pic = await http.MultipartFile.fromPath("image", imageFile.path);
      request.files.add(pic);

      // KIRIM!
      print("Mengirim... User: ${widget.userId}, Loc: Jakarta, Tags: $tagIds");
      var response = await request.send();

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
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

  // ignore: unused_element
  void _showFullScreenPreview() {
    // ... (Kode preview sama kayak sebelumnya)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1080,
                height: 2424,
                child: Stack(
                  children: [
                    // --- HEADER ---
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 1080,
                      height: 290,
                      child: Container(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 40,
                              bottom: 40,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back, size: 60, color: Colors.black),
                              ),
                            ),
                            const Positioned(
                              bottom: 50,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text("New Post", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Positioned(
                              right: 60,
                              bottom: 50,
                              child: GestureDetector(
                                onTap: _isUploading ? null : _uploadPost, // KLIK SHARE -> UPLOAD
                                child: _isUploading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        "Share",
                                        style: TextStyle(fontSize: 35, color: Colors.blue, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- KONTEN ---
                    Positioned(
                      top: 320,
                      left: 0,
                      width: 1080,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PREVIEW
                          GestureDetector(
                            onTap: null, // Matikan preview full biar simpel dlu
                            child: Container(
                              width: 1080,
                              height: 1080,
                              color: Colors.white,
                              padding: widget.isSquareMode ? const EdgeInsets.all(50.0) : EdgeInsets.zero,
                              child: PostCropPreview(
                                entity: widget.entity,
                                isSquareMode: widget.isSquareMode,
                                controller: _readOnlyController,
                                readOnly: true,
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // CAPTION
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: GestureDetector(
                              onTap: _openCaptionEditor,
                              child: Container(
                                color: Colors.transparent,
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 100),
                                child: Text(
                                  _captionText.isEmpty ? "Write a caption..." : _captionText,
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: _captionText.isEmpty ? Colors.grey : Colors.black,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // TAG PEOPLE (WRAP)
                          GestureDetector(
                            onTap: _openTagSearch,
                            child: Container(
                              width: 1080,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 50, color: Colors.black),
                                      const SizedBox(width: 30),
                                      const Text(
                                        "Tag People",
                                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      if (_taggedUsers.isEmpty)
                                        const Icon(Icons.chevron_right, size: 50, color: Colors.grey),
                                    ],
                                  ),
                                  if (_taggedUsers.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 15,
                                      runSpacing: 10,
                                      children: _taggedUsers.map((user) {
                                        return Text(
                                          "@${user.username}",
                                          style: const TextStyle(
                                            fontSize: 30,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // MENU LAIN
                          _buildMenuItem("Add Location", Icons.location_on_outlined),
                          _buildMenuItem("Add Music", Icons.music_note_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // GLOBAL LOADING OVERLAY
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 50, color: Colors.black),
          const SizedBox(width: 30),
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 50, color: Colors.grey),
        ],
      ),
    );
  }
}
