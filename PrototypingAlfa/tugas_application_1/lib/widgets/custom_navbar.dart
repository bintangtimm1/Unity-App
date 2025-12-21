import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex; // Untuk tahu halaman mana yang aktif (0, 1, 2...)
  final Function(int) onItemTapped; // Fungsi 'Remot' untuk ganti halaman

  const CustomNavbar({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    // Container pembungkus Navbar
    return SizedBox(
      width: 1080,
      height: 280, // Sesuaikan tinggi area navbar kamu (misal 200 - 300)
      child: Stack(
        children: [
          // 1. BACKGROUND NAVBAR (Gambar Latar Belakang Putih/Melengkung)
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              'assets/images/bg_nav_bar.png', // Pastikan punya gambar background navbar
              width: 1080,
              fit: BoxFit.cover,
            ),
          ),

          // 2. TOMBOL HOME (Index 0)
          Positioned(
            left: 90, // Koordinat X dari Figma
            top: 35, // Koordinat Y (Relative terhadap kotak Navbar ini, bukan layar penuh)
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: () => onItemTapped(0), // <--- PANGGIL FUNGSI INI
              child: Image.asset(
                // Logika: Kalau selectedIndex 0 (Home), pakai gambar Home Hitam, kalau bukan pakai Abu
                selectedIndex == 0 ? 'assets/images/HomeSelected.png' : 'assets/images/HomeUnSelect.png',
              ),
            ),
          ),

          // 3. TOMBOL Community (Index 1)
          Positioned(
            left: 290,
            top: 35,
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: () => onItemTapped(1), // <--- GANTI ANGKA JADI 1
              child: Image.asset(
                selectedIndex == 1 ? 'assets/images/ComunitySelected.png' : 'assets/images/ComunityUnselected.png',
              ),
            ),
          ),

          // 4. TOMBOL ADD POST (Index 2 - Tombol Tengah)
          Positioned(
            left: 490,
            top: 35,
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: () => onItemTapped(2),
              child: Image.asset(
                selectedIndex == 2 ? 'assets/images/PostingSelected.png' : 'assets/images/PostingUnselected.png',
              ),
            ),
          ),

          // 5. TOMBOL SEARCH (Index 3)
          Positioned(
            left: 690,
            top: 35,
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: () => onItemTapped(3),
              child: Image.asset(
                selectedIndex == 3 ? 'assets/images/SearchSelected.png' : 'assets/images/SearchUnselected.png',
              ),
            ),
          ),
          //6. TOMBOL PROFILE (Index 4)
          Positioned(
            left: 890,
            top: 35,
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: () => onItemTapped(4),
              child: Image.asset(
                selectedIndex == 4 ? 'assets/images/ProfileSelected.png' : 'assets/images/ProfileUnselected.png',
              ),
            ),
          ),
          //lain lain
        ],
      ),
    );
  }
}
