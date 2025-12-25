import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 1. WAJIB IMPORT

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavbar({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.sw, // 100% Lebar Layar
      height: 280.h, // Tinggi Responsif
      child: Stack(
        children: [
          // 1. BACKGROUND NAVBAR
          Positioned(
            left: 0,
            bottom: 0, // Kunci di bawah
            child: Image.asset(
              'assets/images/bg_nav_bar.png',
              width: 1.sw, // Full width responsif
              fit: BoxFit.fitWidth,
            ),
          ),

          // 2. TOMBOL HOME (Index 0)
          Positioned(
            left: 90.w,
            top: 35.h,
            width: 100.w,
            height: 100.w, // Pakai .w juga biar tetap kotak
            child: GestureDetector(
              onTap: () => onItemTapped(0),
              child: Image.asset(
                selectedIndex == 0 ? 'assets/images/HomeSelected.png' : 'assets/images/HomeUnSelect.png',
              ),
            ),
          ),

          // 3. TOMBOL COMMUNITY (Index 1)
          Positioned(
            left: 290.w,
            top: 35.h,
            width: 100.w,
            height: 100.w,
            child: GestureDetector(
              onTap: () => onItemTapped(1),
              child: Image.asset(
                selectedIndex == 1 ? 'assets/images/ComunitySelected.png' : 'assets/images/ComunityUnselected.png',
              ),
            ),
          ),

          // 4. TOMBOL ADD POST (Index 2 - Tengah)
          Positioned(
            left: 490.w,
            top: 35.h,
            width: 100.w,
            height: 100.w,
            child: GestureDetector(
              onTap: () => onItemTapped(2),
              child: Image.asset(
                selectedIndex == 2 ? 'assets/images/PostingSelected.png' : 'assets/images/PostingUnselected.png',
              ),
            ),
          ),

          // 5. TOMBOL SEARCH (Index 3)
          Positioned(
            left: 690.w,
            top: 35.h,
            width: 100.w,
            height: 100.w,
            child: GestureDetector(
              onTap: () => onItemTapped(3),
              child: Image.asset(
                selectedIndex == 3 ? 'assets/images/SearchSelected.png' : 'assets/images/SearchUnselected.png',
              ),
            ),
          ),

          // 6. TOMBOL PROFILE (Index 4)
          Positioned(
            left: 890.w,
            top: 35.h,
            width: 100.w,
            height: 100.w,
            child: GestureDetector(
              onTap: () => onItemTapped(4),
              child: Image.asset(
                selectedIndex == 4 ? 'assets/images/ProfileSelected.png' : 'assets/images/ProfileUnselected.png',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
