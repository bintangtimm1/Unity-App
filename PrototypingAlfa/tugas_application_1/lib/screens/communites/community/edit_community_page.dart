import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../../config.dart';
import '../../post/location_search_page.dart';

class EditCommunityPage extends StatefulWidget {
  final Map<String, dynamic> communityData;
  final int currentUserId;

  const EditCommunityPage({super.key, required this.communityData, required this.currentUserId});

  @override
  State<EditCommunityPage> createState() => _EditCommunityPageState();
}

class _EditCommunityPageState extends State<EditCommunityPage> {
  late TextEditingController _nameController;
  late TextEditingController _subtitleController;
  late TextEditingController _descController;
  String? _selectedLocation;

  File? _iconFile;
  File? _headerFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 🔥 ISI FORM DENGAN DATA LAMA
    _nameController = TextEditingController(text: widget.communityData['name']);
    _subtitleController = TextEditingController(text: widget.communityData['subtitle'] ?? "");
    _descController = TextEditingController(text: widget.communityData['description']);
    _selectedLocation = widget.communityData['location'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- FUNGSI PICK IMAGE (Sama kayak Add Community) ---
  Future<void> _pickImage(bool isHeader) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            aspectRatioPresets: isHeader ? [CropAspectRatioPreset.ratio16x9] : [CropAspectRatioPreset.square],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          if (isHeader) {
            _headerFile = File(croppedFile.path);
          } else {
            _iconFile = File(croppedFile.path);
          }
        });
      }
    }
  }

  // --- FUNGSI SAVE ---
  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name cannot be empty!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse("${Config.baseUrl}/edit_community"));

      // Fields
      request.fields['community_id'] = widget.communityData['id'].toString(); // 🔥 Kunci Edit: ID Komunitas
      request.fields['user_id'] = widget.currentUserId.toString(); // 🔥 Security Check
      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descController.text;
      request.fields['subtitle'] = _subtitleController.text;
      request.fields['location'] = _selectedLocation ?? "";

      // Files (Hanya kirim kalau user ganti gambar)
      if (_iconFile != null) {
        request.files.add(await http.MultipartFile.fromPath('icon', _iconFile!.path));
      }
      if (_headerFile != null) {
        request.files.add(await http.MultipartFile.fromPath('header', _headerFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Sukses
        Navigator.pop(context, true); // Balik ke menu dengan sinyal 'true' (refresh)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Community Updated!")));
      } else {
        var msg = jsonDecode(response.body)['message'] ?? "Update failed";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      print("Error Update: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Community",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    "Save",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 50.h),
        child: Column(
          children: [
            // 1. HEADER IMAGE
            GestureDetector(
              onTap: () => _pickImage(true),
              child: Container(
                height: 350.h,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: _headerFile != null
                    ? Image.file(_headerFile!, fit: BoxFit.cover)
                    : (widget.communityData['header_url'] != null && widget.communityData['header_url'] != "")
                    ? CachedNetworkImage(imageUrl: widget.communityData['header_url'], fit: BoxFit.cover)
                    : Icon(Icons.add_a_photo, size: 50, color: Colors.grey.shade600),
              ),
            ),

            SizedBox(height: 20.h),

            // 2. ICON IMAGE
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Container(
                height: 200.h,
                width: 200.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: ClipOval(
                  child: _iconFile != null
                      ? Image.file(_iconFile!, fit: BoxFit.cover)
                      : (widget.communityData['icon_url'] != null && widget.communityData['icon_url'] != "")
                      ? CachedNetworkImage(imageUrl: widget.communityData['icon_url'], fit: BoxFit.cover)
                      : Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade600),
                ),
              ),
            ),

            SizedBox(height: 30.h),

            // 3. FORM INPUT
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  _buildTextField("Name", _nameController),
                  SizedBox(height: 20.h),
                  _buildTextField("Subtitle", _subtitleController),
                  SizedBox(height: 20.h),
                  _buildLocationSelector(),
                  SizedBox(height: 20.h),
                  _buildTextField("Description", _descController, maxLines: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildLocationSelector() {
    bool hasValue = _selectedLocation != null && _selectedLocation!.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationSearchPage()),
        );
        if (result != null) {
          setState(() => _selectedLocation = result);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? _selectedLocation! : "Select Location",
                style: TextStyle(fontSize: 16, color: hasValue ? Colors.black : Colors.grey),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
