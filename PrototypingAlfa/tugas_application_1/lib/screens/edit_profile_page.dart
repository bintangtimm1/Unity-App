import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({super.key, required this.userProfile, required this.onProfileUpdated});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  File? _avatarFile;
  File? _headerFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userProfile['username']);
    _bioController = TextEditingController(text: widget.userProfile['bio'] ?? "");
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _avatarFile = File(image.path));
  }

  Future<void> _pickHeader() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _headerFile = File(image.path));
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      var uri = Uri.parse("${Config.baseUrl}/update_profile");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = widget.userProfile['id'].toString();
      request.fields['username'] = _usernameController.text;
      request.fields['bio'] = _bioController.text;
      // Website dihapus dulu sesuai request

      if (_avatarFile != null) {
        var pic = await http.MultipartFile.fromPath("avatar", _avatarFile!.path);
        request.files.add(pic);
      }
      if (_headerFile != null) {
        var pic = await http.MultipartFile.fromPath("header", _headerFile!.path);
        request.files.add(pic);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        widget.onProfileUpdated();
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengupdate profil")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String initialHeaderUrl = widget.userProfile['header_url'] ?? "";
    String initialAvatarUrl = widget.userProfile['avatar_url'] ?? "";
    // Lebar header adalah 90% dari lebar layar (biar ada sisa putih di kiri kanan)
    double headerWidth = 0.9.sw;
    double avatarRadius = 120.r;

    return Scaffold(
      backgroundColor: Colors.white,
      // --- APP BAR SESUAI DESAIN ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 150.w,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Back",
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 0, 55),
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(width: 34.w, height: 34.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    "Save",
                    style: TextStyle(color: Colors.blue, fontSize: 34.sp, fontWeight: FontWeight.bold),
                  ),
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h), // Jarak sedikit dari AppBar
            // --- AREA HEADER & AVATAR ---
            Center(
              child: SizedBox(
                width: headerWidth, // Batasi lebar agar ada margin kiri kanan
                // Tinggi menyesuaikan konten Stack (Header + Avatar yang menonjol ke bawah)
                child: Stack(
                  clipBehavior: Clip.none, // Biarkan avatar menonjol keluar batas Stack
                  alignment: Alignment.bottomLeft,
                  children: [
                    // 1. HEADER IMAGE (16:9, Rounded Corner)
                    GestureDetector(
                      onTap: _pickHeader,
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Rasio 16:9
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(80.r), // Sudut membulat
                          child: Container(
                            color: Colors.grey.shade200,
                            child: _headerFile != null
                                ? Image.file(_headerFile!, fit: BoxFit.cover)
                                : (initialHeaderUrl.isNotEmpty
                                      ? CachedNetworkImage(imageUrl: initialHeaderUrl, fit: BoxFit.cover)
                                      : const Center(child: Icon(Icons.add_a_photo, color: Colors.grey))),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -140.h,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // 🔥 1. AVATAR UTAMA (INI YANG DI-KLIK)
                            GestureDetector(
                              onTap: _pickAvatar, // <--- AKSI KLIK PINDAH KE SINI
                              child: Container(
                                padding: EdgeInsets.all(20.r),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: _avatarFile != null
                                      ? FileImage(_avatarFile!)
                                      : (initialAvatarUrl.isNotEmpty
                                                ? CachedNetworkImageProvider(initialAvatarUrl)
                                                : null)
                                            as ImageProvider?,
                                  child: (_avatarFile == null && initialAvatarUrl.isEmpty)
                                      ? Icon(Icons.person, size: avatarRadius, color: Colors.grey)
                                      : null,
                                ),
                              ),
                            ),

                            // 🔥 2. ICON KAMERA (CUMA HIASAN / DEKORASI)
                            // GestureDetector-nya sudah dicopot
                            IgnorePointer(
                              // Tambahan biar klik tembus ke avatar kalau gak sengaja kena ikon
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade200, width: 1),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
                                ),
                                child: Icon(Icons.camera_alt, size: 40.sp, color: Colors.black),
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

            // Jarak kompensasi karena avatar menonjol ke bawah sebanyak 40.h
            SizedBox(height: 180.h), // Jarak dari avatar ke form
            // JUDUL SECTION
            Center(
              child: Column(
                children: [
                  Divider(color: const Color.fromARGB(255, 207, 207, 207), thickness: 3.h),
                  Text(
                    "About Me",
                    style: TextStyle(fontSize: 50.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 0.h),
                ],
              ),
            ),

            SizedBox(height: 50.h),

            // --- FORM FIELDS (MODEL LIST) ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: Column(
                children: [
                  // USERNAME ROW
                  _buildRowInput("Username", _usernameController),

                  // BIO ROW (Multiline)
                  _buildRowInput("Bio", _bioController, maxLines: null), // null = auto expand

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowInput(String label, TextEditingController controller, {int? maxLines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250.w,
            child: Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 116, 116, 116),
                ),
              ),
            ),
          ),

          // 2. INPUT FIELD (KANAN) - INI YANG PAKAI GARIS
          Expanded(
            child: Container(
              // 🔥 GARIS PINDAH KE SINI (Cuma di bawah input)
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 3.h),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: maxLines, // null = auto expand ke bawah
                minLines: 1, // Minimal 1 baris
                style: TextStyle(
                  fontSize: 40.sp,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.w500,
                  height: 1.5, // Spasi antar baris biar garisnya gak mepet banget
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 15.h, top: 10.h), // Jarak teks ke garis bawah
                  border: InputBorder.none, // Hapus border bawaan TextField
                  hintText: "Enter $label",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
