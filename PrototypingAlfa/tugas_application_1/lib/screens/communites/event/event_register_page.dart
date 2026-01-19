import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class EventRegisterPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final int userId; // 🔥 Kita butuh userId buat dikirim ke backend

  const EventRegisterPage({super.key, required this.eventData, required this.userId});

  @override
  State<EventRegisterPage> createState() => _EventRegisterPageState();
}

class _EventRegisterPageState extends State<EventRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  // --- LOGIC REGISTER ---
  Future<void> _submitRegistration() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse("${Config.baseUrl}/register_event_official");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = widget.userId.toString();
      request.fields['event_id'] = widget.eventData['id'].toString();
      request.fields['full_name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone_number'] = _phoneController.text;

      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);

      if (response.statusCode == 201) {
        // SUKSES
        if (mounted) {
          // Tampilkan Dialog Sukses
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Icon(Icons.check_circle, color: Colors.green, size: 60.sp),
              content: Text(
                "Registration Successful!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Tutup Dialog
                    Navigator.pop(context); // Tutup Halaman Register (Balik ke Detail)
                    Navigator.pop(context); // Tutup Halaman Detail (Balik ke List - Opsional)
                  },
                  child: Text("OK", style: TextStyle(fontSize: 30.sp)),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? "Failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 40.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Registration",
          style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 50.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),

            // JUDUL EVENT
            Text(
              "Registering for:",
              style: TextStyle(color: Colors.grey, fontSize: 30.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              widget.eventData['title'] ?? "Event Name",
              style: TextStyle(color: Colors.black, fontSize: 45.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 60.h),

            // FORM INPUT
            _buildInputLabel("Full Name"),
            _buildTextField(_nameController, "Enter your full name", Icons.person_outline),

            SizedBox(height: 40.h),

            _buildInputLabel("Email Address"),
            _buildTextField(
              _emailController,
              "Enter your active email",
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            SizedBox(height: 40.h),

            _buildInputLabel("WhatsApp Number"),
            _buildTextField(
              _phoneController,
              "e.g 08123456789",
              Icons.phone_android,
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 80.h),

            // TOMBOL SUBMIT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 30.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 30.w,
                        height: 30.w,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        "Submit Registration",
                        style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPER
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Text(
        label,
        style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 34.sp),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 32.sp),
          icon: Icon(icon, color: Colors.grey, size: 40.sp),
        ),
      ),
    );
  }
}
