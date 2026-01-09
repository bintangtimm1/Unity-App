import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'edit_community_page.dart'; // 🔥 Import Halaman Edit

class MenuCommunityPage extends StatelessWidget {
  final Map<String, dynamic> communityData; // 🔥 Ganti ID jadi Data Lengkap
  final int currentUserId;

  // Constructor terima data lengkap biar bisa di-oper ke Edit Page
  const MenuCommunityPage({super.key, required this.communityData, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 50.sp),
        ),
        title: Text(
          "Community Tools",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),

      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        children: [
          _buildSectionTitle("General"),

          // 1. Edit Profile (SUDAH AKTIF)
          _buildMenuTile(
            Icons.edit,
            "Edit Profile",
            Colors.blue,
            onTap: () async {
              // 🔥 Navigasi ke Halaman Edit
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCommunityPage(communityData: communityData, currentUserId: currentUserId),
                ),
              );

              // Kalau result true (berhasil edit), kita balik ke Profile biar refresh
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),

          // 2. Members (Placeholder)
          _buildMenuTile(Icons.people, "Members", Colors.orange, onTap: () {}),

          // 3. Events (Placeholder)
          _buildMenuTile(Icons.event, "Events Management", Colors.purple, onTap: () {}),

          Divider(height: 60.h, thickness: 1, color: Colors.grey.shade200),
          _buildSectionTitle("Danger Zone"),

          // 4. Delete (Placeholder)
          _buildMenuTile(Icons.delete_forever, "Delete Community", Colors.red, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(50.w, 30.h, 50.w, 20.h),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 32.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
      leading: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 50.sp),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 30.sp),
    );
  }
}
