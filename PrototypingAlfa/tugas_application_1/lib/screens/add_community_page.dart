import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddCommunityPage extends StatefulWidget {
  final int userId;
  const AddCommunityPage({super.key, required this.userId});

  @override
  State<AddCommunityPage> createState() => _AddCommunityPageState();
}

class _AddCommunityPageState extends State<AddCommunityPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  File? _iconFile; // Mirip Avatar
  File? _headerFile; // Mirip Header
  final ImagePicker _picker = ImagePicker();

  // Dummy Loading
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _iconFile = File(image.path));
  }

  Future<void> _pickHeader() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _headerFile = File(image.path));
  }

  // 🔥 FUNGSI CREATE DUMMY
  void _createCommunity() {
    print("=== DUMMY CREATE COMMUNITY ===");
    print("User ID: ${widget.userId}");
    print("Name: ${_nameController.text}");
    print("Desc: ${_descController.text}");
    print("Header: ${_headerFile?.path ?? 'None'}");
    print("Icon: ${_iconFile?.path ?? 'None'}");

    // Simulasi Loading
    setState(() => _isCreating = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Create Community Button Pressed (Backend Not Connected Yet)")));
    });
  }

  @override
  Widget build(BuildContext context) {
    double headerWidth = 0.9.sw;
    double iconRadius = 120.r;

    return Scaffold(
      backgroundColor: Colors.white,
      // --- APP BAR CUSTOM ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 150.w,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Back",
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 0, 55), // Warna Merah sesuai request
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          "Create", // Judul Header
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createCommunity, // Panggil fungsi dummy
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

            // --- AREA GAMBAR (HEADER & ICON) ---
            Center(
              child: SizedBox(
                width: headerWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    // 1. HEADER IMAGE (16:9)
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

                    // 2. ICON COMMUNITY (OVERLAP)
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

            SizedBox(height: 180.h), // Jarak kompensasi overlap
            // --- FORM FIELDS ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: Column(
                children: [
                  _buildRowInput("Name", _nameController),
                  _buildRowInput("Description", _descController, maxLines: 4),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 WIDGET INPUT ROW (Label Kiri, Input Kanan + Garis Bawah)
  Widget _buildRowInput(String label, TextEditingController controller, {int? maxLines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LABEL
          SizedBox(
            width: 300.w, // Sedikit lebih lebar buat "Description"
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

          // INPUT FIELD
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
}
