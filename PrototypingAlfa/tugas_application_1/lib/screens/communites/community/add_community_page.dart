import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // 🔥 1. IMPORT CROPPER
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../post/location_search_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import 'community_profile_page.dart'; // Import halaman profil baru

class AddCommunityPage extends StatefulWidget {
  final int userId;
  const AddCommunityPage({super.key, required this.userId});

  @override
  State<AddCommunityPage> createState() => _AddCommunityPageState();
}

class _AddCommunityPageState extends State<AddCommunityPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController(); // 🔥 2. CONTROLLER SUBTITLE
  final TextEditingController _descController = TextEditingController();

  File? _iconFile;
  File? _headerFile;
  final ImagePicker _picker = ImagePicker();

  String? _selectedLocation;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // 🔥 3. FUNGSI CROPPER (REUSABLE)
  Future<File?> _cropImage({required File imageFile, required CropAspectRatioPreset preset}) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Position & Crop',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          initAspectRatio: preset,
          lockAspectRatio: true, // KUNCI RASIO
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Position & Crop', aspectRatioLockEnabled: true),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  // 🔥 4. PICK ICON (CROP SQUARE 1:1)
  Future<void> _pickIcon() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? cropped = await _cropImage(
        imageFile: File(image.path),
        preset: CropAspectRatioPreset.square, // Preset Persegi
      );
      if (cropped != null) setState(() => _iconFile = cropped);
    }
  }

  // 🔥 5. PICK HEADER (CROP 16:9)
  Future<void> _pickHeader() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? cropped = await _cropImage(
        imageFile: File(image.path),
        preset: CropAspectRatioPreset.ratio16x9, // Preset Persegi Panjang
      );
      if (cropped != null) setState(() => _headerFile = cropped);
    }
  }

  void _openLocationSearch() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSearchPage()));

    if (result != null && result is String) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  // 🔥 FUNGSI CREATE COMMUNITY (SUDAH AKTIF & KONEK API)
  Future<void> _createCommunity() async {
    if (_nameController.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Location are required!")));
      return;
    }

    setState(() => _isCreating = true);

    try {
      var uri = Uri.parse("${Config.baseUrl}/create_community");
      var request = http.MultipartRequest("POST", uri);

      // 1. Kirim Data Teks
      request.fields['user_id'] = widget.userId.toString();
      request.fields['name'] = _nameController.text;
      request.fields['subtitle'] = _subtitleController.text; // Subtitle
      request.fields['description'] = _descController.text;
      request.fields['location'] = _selectedLocation!;

      // 2. Kirim File Gambar (Jika ada)
      if (_iconFile != null) {
        var icon = await http.MultipartFile.fromPath("icon", _iconFile!.path);
        request.files.add(icon);
      }
      if (_headerFile != null) {
        var header = await http.MultipartFile.fromPath("header", _headerFile!.path);
        request.files.add(header);
      }

      // 3. Eksekusi
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 201) {
        int newCommunityId = jsonResponse['id']; // Ambil ID komunitas baru

        if (mounted) {
          // Sukses! Pindah ke Halaman Profil Komunitas Baru
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityProfilePage(communityId: newCommunityId, currentUserId: widget.userId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${jsonResponse['message']}")));
        }
      }
    } catch (e) {
      print("Error create community: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double headerWidth = 0.9.sw;
    double iconRadius = 120.r;

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
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          "Create",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createCommunity,
            child: _isCreating
                ? SizedBox(width: 34.w, height: 34.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    "Create",
                    style: TextStyle(color: Colors.blue, fontSize: 34.sp, fontWeight: FontWeight.bold),
                  ),
          ),
          SizedBox(width: 20.w),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // --- HEADER & ICON ---
            Center(
              child: SizedBox(
                width: headerWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    // HEADER IMAGE
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
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 80.sp, color: Colors.grey),
                                      Text(
                                        "Add Cover",
                                        style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // ICON IMAGE
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -140.h,
                      child: Center(
                        child: GestureDetector(
                          onTap: _pickIcon,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20.r),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: iconRadius,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: _iconFile != null ? FileImage(_iconFile!) : null,
                                  child: _iconFile == null
                                      ? Icon(Icons.groups, size: iconRadius, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              if (_iconFile == null)
                                Positioned(
                                  bottom: 20.h,
                                  right: 20.w,
                                  child: Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Icon(Icons.camera_alt, size: 40.sp, color: Colors.black),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 180.h),

            // --- FORM FIELDS ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: Column(
                children: [
                  _buildRowInput("Name", _nameController),

                  // 🔥 6. SUBTITLE BARU
                  _buildRowInput("Sub", _subtitleController),

                  _buildRowInput("Description", _descController, maxLines: 4),

                  _buildLocationInput(),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET INPUT TEXT
  Widget _buildRowInput(String label, TextEditingController controller, {int? maxLines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300.w,
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
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 3.h),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                minLines: 1,
                style: TextStyle(fontSize: 40.sp, color: Colors.black, fontWeight: FontWeight.w500, height: 1.5),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 15.h, top: 10.h),
                  border: InputBorder.none,
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

  // WIDGET INPUT LOKASI
  Widget _buildLocationInput() {
    bool hasValue = _selectedLocation != null && _selectedLocation!.isNotEmpty;

    return GestureDetector(
      onTap: _openLocationSearch,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300.w,
              child: Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Text(
                  "Location",
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 116, 116, 116),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 3.h),
                  ),
                ),
                padding: EdgeInsets.only(bottom: 15.h, top: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasValue ? _selectedLocation! : "Select Location",
                        style: TextStyle(
                          fontSize: 40.sp,
                          color: hasValue ? Colors.black : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 40.sp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
