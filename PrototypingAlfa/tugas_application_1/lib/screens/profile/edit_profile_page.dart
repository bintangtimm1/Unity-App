import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({super.key, required this.userProfile, required this.onProfileUpdated});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  // 🔥 VARIABLE ERROR (SATPAM)
  String? _usernameError;

  File? _avatarFile;
  File? _headerFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.userProfile['display_name'] ?? widget.userProfile['username'],
    );
    _usernameController = TextEditingController(text: widget.userProfile['username']);
    _bioController = TextEditingController(text: widget.userProfile['bio'] ?? "");
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 🔥 FUNGSI VALIDASI REAL-TIME (CCTV)
  void _validateUsername(String value) {
    String? newError;

    if (value.isEmpty) {
      newError = "Username tidak boleh kosong!";
    } else if (value.contains(' ')) {
      newError = "Tidak boleh ada spasi!";
    } else if (value != value.toLowerCase()) {
      newError = "Gunakan huruf kecil semua!";
    } else {
      final validCharacters = RegExp(r'^[a-z0-9._]+$');
      if (!validCharacters.hasMatch(value)) {
        newError = "Hanya huruf, angka, titik, & underscore!";
      }
    }

    // Hanya update UI jika status error berubah (biar gak kedip)
    if (_usernameError != newError) {
      setState(() {
        _usernameError = newError;
      });
    }
  }

  // --- CROPPER HELPERS ---
  Future<File?> _cropImage({required File imageFile, required CropAspectRatioPreset preset}) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Position & Crop',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          initAspectRatio: preset,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Position & Crop', aspectRatioLockEnabled: true),
      ],
    );
    if (croppedFile != null) return File(croppedFile.path);
    return null;
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? cropped = await _cropImage(imageFile: File(image.path), preset: CropAspectRatioPreset.square);
      if (cropped != null) setState(() => _avatarFile = cropped);
    }
  }

  Future<void> _pickHeader() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? cropped = await _cropImage(imageFile: File(image.path), preset: CropAspectRatioPreset.ratio16x9);
      if (cropped != null) setState(() => _headerFile = cropped);
    }
  }

  Future<void> _saveProfile() async {
    // 🔥 CEK VALIDASI TERAKHIR SEBELUM KIRIM
    _validateUsername(_usernameController.text);
    if (_usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_usernameError!), backgroundColor: Colors.red));
      return; // STOP DISINI JIKA ERROR
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      var uri = Uri.parse("${Config.baseUrl}/update_profile");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = widget.userProfile['id'].toString();
      request.fields['display_name'] = _displayNameController.text;
      request.fields['username'] = _usernameController.text; // Kirim username yang sudah valid
      request.fields['bio'] = _bioController.text;

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
    double headerWidth = 0.9.sw;
    double avatarRadius = 120.r;

    return Scaffold(
      backgroundColor: Colors.white,
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
              fontSize: 32.sp,
              fontWeight: FontWeight.w600,
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
            // 🔥 DISABLE TOMBOL SAVE KALAU ADA ERROR
            onPressed: (_isSaving || _usernameError != null) ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(width: 34.w, height: 34.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    "Save",
                    style: TextStyle(
                      // Warnanya jadi abu-abu kalau error/disabled
                      color: (_usernameError != null) ? Colors.grey : Colors.blue,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // --- AREA HEADER & AVATAR ---
            Center(
              child: SizedBox(
                width: headerWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    // HEADER
                    GestureDetector(
                      onTap: _pickHeader,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(80.r),
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
                    // AVATAR
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -140.h,
                      child: Center(
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _avatarFile != null
                                  ? FileImage(_avatarFile!)
                                  : (initialAvatarUrl.isNotEmpty ? CachedNetworkImageProvider(initialAvatarUrl) : null)
                                        as ImageProvider?,
                              child: (_avatarFile == null && initialAvatarUrl.isEmpty)
                                  ? Icon(Icons.person, size: avatarRadius, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 180.h),
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

            // --- FORM FIELDS ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: Column(
                children: [
                  // 1. NAME (Bebas, gak perlu validasi)
                  _buildRowInput("Name", _displayNameController),

                  // 🔥 2. USERNAME (DENGAN VALIDASI & ERROR MESSAGE)
                  _buildRowInput(
                    "Username",
                    _usernameController,
                    errorText: _usernameError, // Kirim error
                    onChanged: _validateUsername, // Kirim fungsi validasi
                  ),

                  // 3. BIO
                  _buildRowInput("Bio", _bioController, maxLines: null),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATE WIDGET BUILDER: TERIMA ERROR & ONCHANGED
  Widget _buildRowInput(
    String label,
    TextEditingController controller, {
    int? maxLines = 1,
    String? errorText,
    Function(String)? onChanged,
  }) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 JIKA ADA ERROR, TAMPILKAN DI ATAS INPUT (MERAH TEBAL)
                if (errorText != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      errorText,
                      style: TextStyle(color: Colors.red, fontSize: 32.sp, fontWeight: FontWeight.bold),
                    ),
                  ),

                // INPUT FIELD
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      // Kalau error, garis bawahnya jadi merah juga
                      bottom: BorderSide(color: errorText != null ? Colors.red : Colors.grey.shade300, width: 3.h),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: maxLines,
                    minLines: 1,
                    onChanged: onChanged, // Hook validasi real-time
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(bottom: 15.h, top: 10.h),
                      border: InputBorder.none,
                      hintText: "Enter $label",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
