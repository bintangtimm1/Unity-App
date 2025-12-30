import 'dart:ui'; // WAJIB: Buat ImageFilter
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlurHeader extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double blurStrength; // Bisa diatur blurnya
  final double overlayOpacity; // Bisa diatur gelapnya

  const BlurHeader({
    super.key,
    required this.imageUrl,
    required this.height,
    this.blurStrength = 10.0, // Default blur level
    this.overlayOpacity = 1.0, // Default kegelapan (0.0 - 1.0)
  });

  @override
  Widget build(BuildContext context) {
    // Kalau gambar kosong/null, kasih warna abu aja
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(height: height, color: Colors.grey.shade300);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. LAYER GAMBAR YANG DI-BLUR
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              // Kasih placeholder biar gak glitch pas loading
              placeholder: (context, url) => Container(color: Colors.grey.shade300),
              errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
            ),
          ),

          // 2. LAYER OVERLAY HITAM TRANSPARAN
          // Ini penting banget biar tulisan/icon di atasnya gak 'tenggelam'
          Container(color: const Color.fromARGB(0, 0, 0, 0).withOpacity(overlayOpacity)),
        ],
      ),
    );
  }
}
