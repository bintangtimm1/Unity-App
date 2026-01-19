import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../auth/login_page.dart'; // Pastikan import Login Page buat logout

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Garis tipis di bawah header
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 60.sp),
        ),
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
      ),

      // --- ISI MENU ---
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        children: [
          _buildSectionTitle("Account"),
          _buildMenuTile(Icons.person_outline, "Edit Profile", onTap: () {}),
          _buildMenuTile(Icons.lock_outline, "Change Password", onTap: () {}),
          _buildMenuTile(Icons.notifications_none, "Notifications", onTap: () {}),
          _buildMenuTile(Icons.privacy_tip_outlined, "Privacy", onTap: () {}),

          SizedBox(height: 40.h),
          _buildSectionTitle("Support"),
          _buildMenuTile(Icons.help_outline, "Help Center", onTap: () {}),
          _buildMenuTile(Icons.info_outline, "About Us", onTap: () {}),

          SizedBox(height: 60.h),
          // TOMBOL LOGOUT
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: TextButton(
              onPressed: () {
                // Logika Logout Sederhana: Balik ke Login & Hapus semua history
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 30.h),
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
              child: Text(
                "Log Out",
                style: TextStyle(color: Colors.red, fontSize: 35.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: 50.h),
          Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 30.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(50.w, 20.h, 50.w, 20.h),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 32.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
      leading: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black, size: 50.sp),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 50.sp),
    );
  }
}
