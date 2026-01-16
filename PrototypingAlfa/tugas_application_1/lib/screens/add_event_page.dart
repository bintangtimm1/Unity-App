import 'dart:io';
import 'package:flutter/cupertino.dart'; // 🔥 IMPORT CUPERTINO UNTUK IOS ALERT
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../widgets/location_input_widget.dart';
import 'select_organizer_page.dart';
import 'event_description_page.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AddEventPage extends StatefulWidget {
  final int userId;
  const AddEventPage({super.key, required this.userId});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  // Controller Title
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();

  // Simpan text deskripsi
  String _descriptionText = "";
  String _mapsLink = "";

  File? _imageFile;
  Map<String, dynamic>? _selectedCommunity;
  bool _isCreating = false;

  // Tanggal
  DateTime? _startDate;
  DateTime? _dueDate;
  DateTime? _preRegDate;
  DateTime? _closeRegDate;

  final ImagePicker _picker = ImagePicker();

  // --- PICKER FUNGSI ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onPicked) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _openDescriptionPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDescriptionPage(initialText: _descriptionText)),
    );
    if (result != null) setState(() => _descriptionText = result);
  }

  // 🔥 FUNGSI IOS POPUP ALERT (REVISI UTAMA)
  void _showIOSAlert(String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "Attention !",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), // Judul Bold
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 16), // 🔥 Teks Merah sesuai request
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              "OK",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // --- VALIDASI LOGIC ---
  void _validateAndCreate() {
    // 1. CEK EMPTY FIELDS (Sesuai Pesan Error Request)
    if (_imageFile == null) {
      _showIOSAlert("Image must be uploaded");
      return;
    }
    if (_selectedCommunity == null) {
      _showIOSAlert("Organizer must be selected"); // Atau "chosed" sesuai gambar, tapi selected lebih tepat grammar-nya
      return;
    }
    if (_titleController.text.isEmpty) {
      _showIOSAlert("Please add Title");
      return;
    }
    if (_descriptionText.isEmpty) {
      _showIOSAlert("Please add description");
      return;
    }
    if (_startDate == null) {
      _showIOSAlert("Please insert event time"); // Start Event
      return;
    }
    if (_dueDate == null) {
      _showIOSAlert("Please insert Due Date");
      return;
    }
    if (_preRegDate == null) {
      _showIOSAlert("Please insert Pre Register date");
      return;
    }
    if (_closeRegDate == null) {
      _showIOSAlert("Please insert Close Register date");
      return;
    }

    // 2. CEK LOGIC TANGGAL (STRICT RULES)

    // Rule: Open register tidak boleh saat event di mulai (Harus SEBELUM)
    if (_preRegDate!.isAfter(_startDate!) || _preRegDate!.isAtSameMomentAs(_startDate!)) {
      _showIOSAlert("Pre-Register must be BEFORE Start Event!");
      return;
    }

    // Rule: Close register harus ada diantara open register dan start
    if (_closeRegDate!.isBefore(_preRegDate!) || _closeRegDate!.isAtSameMomentAs(_preRegDate!)) {
      _showIOSAlert("Close Register must be AFTER Pre-Register!");
      return;
    }
    if (_closeRegDate!.isAfter(_startDate!) || _closeRegDate!.isAtSameMomentAs(_startDate!)) {
      _showIOSAlert("Close Register must be BEFORE Start Event!");
      return;
    }

    // Rule: Due date tidak boleh sama dengan start event (Harus SETELAH)
    if (_dueDate!.isBefore(_startDate!) || _dueDate!.isAtSameMomentAs(_startDate!)) {
      _showIOSAlert("Due Date must be AFTER Start Event!");
      return;
    }

    // LOLOS VALIDASI -> HIT API
    _createEventApi();
  }

  Future<void> _createEventApi() async {
    setState(() => _isCreating = true);
    try {
      var uri = Uri.parse("${Config.baseUrl}/create_event");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = widget.userId.toString();
      request.fields['community_id'] = _selectedCommunity!['id'].toString();
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionText;
      request.fields['location'] = "_locationNameController.text;";
      request.fields['start_time'] = _startDate.toString();
      request.fields['end_time'] = _dueDate.toString();

      if (_imageFile != null) {
        var img = await http.MultipartFile.fromPath("image", _imageFile!.path);
        request.files.add(img);
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Event Created Successfully!")));
        }
      } else {
        _showIOSAlert("Failed to create event. Server Error.");
      }
    } catch (e) {
      _showIOSAlert("Error: $e");
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Create Event",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _validateAndCreate,
            child: _isCreating
                ? SizedBox(width: 30.w, height: 30.w, child: CircularProgressIndicator())
                : Text(
                    "Create",
                    style: TextStyle(color: Colors.blue, fontSize: 34.sp, fontWeight: FontWeight.bold),
                  ),
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 50.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),

            // 1. IMAGE UPLOAD (16:9)
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(50.r),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 80.sp, color: Colors.grey),
                            SizedBox(height: 20.h),
                            Text(
                              "Add Event Cover",
                              style: TextStyle(fontSize: 30.sp, color: Colors.grey),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),

            SizedBox(height: 60.h),
            Text(
              "Organizer",
              style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),

            // 2. SELECT ORGANIZER
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectOrganizerPage(userId: widget.userId)),
                );
                if (result != null) {
                  setState(() => _selectedCommunity = result);
                }
              },
              child: _buildClickableBox(
                text: _selectedCommunity != null ? _selectedCommunity!['name'] : "Choose Community",
                isActive: _selectedCommunity != null,
                // 🔥 TAMBAHAN BARU: Kirim URL Icon jika ada
                imageUrl: _selectedCommunity != null ? _selectedCommunity!['icon_url'] : null,
              ),
            ),

            SizedBox(height: 40.h),

            // 3. TITLE & DESC
            _buildTextInput("Add Title", _titleController),

            GestureDetector(
              onTap: _openDescriptionPage,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 30.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 2.h),
                  ),
                ),
                child: Text(
                  _descriptionText.isEmpty ? "Add description" : _descriptionText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 40.sp,
                    color: _descriptionText.isEmpty ? Colors.grey.shade400 : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            SizedBox(height: 60.h),

            // --- KOLOM LOKASI MANUAL ---
            _buildTextInput("Location Name (ex: Plaza Indonesia)", _locationNameController), // Asumsi kamu punya ini

            SizedBox(height: 40.h),

            // 🔥 DISINI KITA TEMPEL WIDGET BARUNYA
            LocationInputWidget(
              onLocationChanged: (link) {
                setState(() {
                  _mapsLink = link; // Simpan link ke variable utama
                });
                print("Link maps tersimpan: $_mapsLink");
              },
            ),

            SizedBox(height: 60.h),

            // 4. DATES
            _buildDateButton("Start Event", _startDate, (val) => _startDate = val),
            SizedBox(height: 30.h),
            _buildDateButton("Due Date (Event Ends)", _dueDate, (val) => _dueDate = val),

            SizedBox(height: 60.h),

            // 5. REGISTRATION (GROUPED)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 153, 153, 153).withOpacity(0.2), width: 2),
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: Column(
                children: [
                  _buildDateButton("Pre Register", _preRegDate, (val) => _preRegDate = val, isGrouped: true),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildDateButton("Close Register", _closeRegDate, (val) => _closeRegDate = val, isGrouped: true),
                ],
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPERS
  Widget _buildTextInput(String hint, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2.h),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 45.sp, color: Colors.black, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 40.sp),
        ),
      ),
    );
  }

  Widget _buildClickableBox({required String text, required bool isActive, String? imageUrl}) {
    return Container(
      // Padding kita atur biar kalau ada gambar dia lega, kalau teks doang dia rapi
      padding: EdgeInsets.symmetric(vertical: isActive ? 20.h : 30.h, horizontal: 25.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // 🔥 LOGIC GAMBAR: Tampilkan Avatar jika ada image URL
                if (isActive) ...[
                  CircleAvatar(
                    radius: 50.r, // Ukuran gambar (akan bikin kotak membesar)
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? Icon(Icons.groups, size: 50.sp, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(width: 30.w), // Jarak antara gambar dan teks
                ],

                // TEKS NAMA ORGANISASI
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Biar kalau nama panjang gak error
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: isActive ? Colors.black : Colors.grey.shade400,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ICON PANAH KANAN
          Icon(Icons.chevron_right, size: 50.sp, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? value, Function(DateTime) onSave, {bool isGrouped = false}) {
    return GestureDetector(
      onTap: () => _selectDate(context, onSave),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 40.w),
        decoration: isGrouped
            ? null
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                if (value != null)
                  Text(
                    _formatDate(value),
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 0, 76),
                      fontWeight: FontWeight.bold,
                      fontSize: 38.sp,
                    ),
                  ),
                SizedBox(width: 20.w),
                Icon(Icons.chevron_right, size: 40.sp, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
