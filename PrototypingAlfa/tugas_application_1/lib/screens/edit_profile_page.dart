import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http; // Import HTTP
import '../config.dart'; // Import Config buat BaseURL

class EditProfilePage extends StatefulWidget {
  final int userId; // 🔥 WAJIB: Butuh ID buat tau siapa yang diedit
  final String currentAvatarUrl;
  final String currentHeaderUrl;
  final String currentUsername;
  final String currentBio;

  const EditProfilePage({
    super.key,
    required this.userId, // Tambahin ini
    required this.currentAvatarUrl,
    required this.currentHeaderUrl,
    required this.currentUsername,
    required this.currentBio,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _pickedHeader;
  File? _pickedAvatar;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false; // Loading state pas upload

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _bioController = TextEditingController(text: widget.currentBio);
  }

  Future<void> _pickImage({required bool isHeader}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: isHeader
          ? const CropAspectRatio(ratioX: 16, ratioY: 9)
          : const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isHeader ? 'Atur Header' : 'Atur Avatar',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          initAspectRatio: isHeader ? CropAspectRatioPreset.ratio16x9 : CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Edit Foto', aspectRatioLockEnabled: true),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        if (isHeader) {
          _pickedHeader = File(croppedFile.path);
        } else {
          _pickedAvatar = File(croppedFile.path);
        }
      });
    }
  }

  // 🔥 FUNGSI UTAMA: UPLOAD KE SERVER 🔥
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      // 1. Siapkan Request Multipart (Buat kirim file + text)
      // Pastikan endpoint di servermu namanya 'update_profile' atau sesuaikan!
      var request = http.MultipartRequest('POST', Uri.parse("${Config.baseUrl}/update_profile"));

      // 2. Masukkan Data Teks
      request.fields['user_id'] = widget.userId.toString();
      request.fields['username'] = _usernameController.text;
      request.fields['bio'] = _bioController.text;

      // 3. Masukkan File (Jika ada perubahan)
      // Cek apakah user ganti Avatar?
      if (_pickedAvatar != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar', // <-- Pastikan nama key ini SAMA dengan di PHP/Backend ($FILES['avatar'])
            _pickedAvatar!.path,
          ),
        );
      }

      // Cek apakah user ganti Header?
      if (_pickedHeader != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'header', // <-- Pastikan nama key ini SAMA dengan di PHP/Backend ($FILES['header'])
            _pickedHeader!.path,
          ),
        );
      }

      // 4. Kirim Request
      var response = await request.send();

      // 5. Cek Hasil
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diupdate! ✅")));
          Navigator.pop(context, true); // Balik ke halaman profil bawa kabar sukses
        }
      } else {
        print("Gagal upload: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update profil ❌")));
        }
      }
    } catch (e) {
      print("Error upload: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double headerHeight = screenWidth * (9 / 16);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol Save
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue, size: 30),
                  onPressed: _saveProfile, // Panggil fungsi upload
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Header & Avatar (Code sama kayak sebelumnya)
            SizedBox(
              height: headerHeight + 60,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(isHeader: true),
                    child: Container(
                      height: headerHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        image: _pickedHeader != null
                            ? DecorationImage(image: FileImage(_pickedHeader!), fit: BoxFit.cover)
                            : (widget.currentHeaderUrl != ""
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(widget.currentHeaderUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child: Container(
                        color: Colors.black26,
                        child: const Center(child: Icon(Icons.camera_alt, color: Colors.white, size: 40)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(isHeader: false),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _pickedAvatar != null
                                  ? FileImage(_pickedAvatar!)
                                  : (widget.currentAvatarUrl != ""
                                            ? CachedNetworkImageProvider(widget.currentAvatarUrl)
                                            : null)
                                        as ImageProvider?,
                            ),
                          ),
                          const Icon(Icons.camera_alt, color: Colors.white70, size: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Bio",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
