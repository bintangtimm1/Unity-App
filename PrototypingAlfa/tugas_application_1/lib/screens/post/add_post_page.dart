import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Wajib buat RepaintBoundary
import 'package:path_provider/path_provider.dart'; // Wajib ada di pubspec.yaml
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/post_crop_preview.dart'; // Pastikan ini pakai file yang sudah diperbaiki (Dynamic Canvas)
import 'post_upload_page.dart';

class AddPostPage extends StatefulWidget {
  final int userId;
  const AddPostPage({super.key, required this.userId});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  // --- VARIABLES ---
  List<AssetEntity> _mediaList = [];
  AssetEntity? _selectedEntity;
  bool _isCoverMode = true; // true = Square (1:1), false = Portrait (4:5)
  List<AssetPathEntity> _albumList = [];
  AssetPathEntity? _currentAlbum;
  bool _isNewestFirst = true;
  bool _isMenuOpen = false;
  bool _isProcessing = false; // Loading state saat cropping

  ScrollPhysics _pageScrollPhysics = const BouncingScrollPhysics();

  // Controller ini dipakai BERSAMA oleh Layer Depan & Belakang
  final TransformationController _cropController = TransformationController();

  // Key khusus untuk menangkap gambar di Layer Belakang
  final GlobalKey _cleanCropKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  Future<void> _fetchNewMedia() async {
    await PhotoManager.requestPermissionExtend();
    try {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image, hasAll: true);
      if (albums.isNotEmpty) {
        _currentAlbum = albums[0];
        _albumList = albums;
        await _loadPhotosFromCurrentAlbum();
      }
    } catch (e) {
      print("Error load album: $e");
    }
  }

  Future<void> _loadPhotosFromCurrentAlbum() async {
    if (_currentAlbum == null) return;
    List<AssetEntity> photos = await _currentAlbum!.getAssetListPaged(page: 0, size: 100);
    if (!_isNewestFirst) photos = photos.reversed.toList();

    setState(() {
      _mediaList = photos;
      if (_mediaList.isNotEmpty && _selectedEntity == null) {
        _selectedEntity = _mediaList[0];
      }
    });
  }

  // 🔥 FUNGSI UTAMA: JALANKAN CROP & PINDAH HALAMAN
  Future<void> _cropAndNavigate() async {
    if (_selectedEntity == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Cari Widget 'Layer Belakang' yang bersih
      RenderRepaintBoundary? boundary = _cleanCropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Gagal merender crop");

      // 2. Foto widget tersebut dengan resolusi tinggi (pixelRatio 3.0 biar tajam)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 3. Simpan hasil foto ke file sementara (.png)
      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/clean_crop_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await imagePath.writeAsBytes(pngBytes);

      // 4. Kirim FILE MATANG ke PostUploadPage
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostUploadPage(
              imageFile: imagePath, // Kita kirim File, bukan data mentah lagi
              isSquareMode: _isCoverMode,
              userId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            // ============================================================
            // 🔥 LAYER 0 (BELAKANG): SI KEMBAR POLOS (GHOST WIDGET)
            // Ini tidak terlihat user (ketutup Layer 1), tapi ini yang kita FOTO.
            // Ukurannya DINAMIS (Square / Portrait) biar hasil crop akurat.
            // ============================================================
            Positioned(
              left: 0,
              top: 0,
              // Kita taruh di luar layar atau tumpuk di bawah.
              // RepaintBoundary tetap bekerja walaupun ketutup widget lain.
              child: RepaintBoundary(
                key: _cleanCropKey, // <--- CCTV KITA DISINI
                child: Container(
                  width: 1.sw,
                  // Tinggi mengikuti mode: 1.sw (Kotak) atau 1.25.sw (Portrait)
                  height: _isCoverMode ? 1.sw : 1.25.sw,
                  color: Colors.white,
                  // Isi kontennya SAMA PERSIS dengan preview user
                  child: _selectedEntity != null
                      ? PostCropPreview(
                          entity: _selectedEntity!,
                          isSquareMode: _isCoverMode,
                          controller: _cropController, // Pakai controller SAMA biar gerakannya sinkron
                          readOnly: true, // ReadOnly = Gak ada grid/tombol/indikator scroll
                        )
                      : const SizedBox(),
                ),
              ),
            ),

            // ============================================================
            // 🔥 LAYER 1 (DEPAN): UI VISUAL (INTERAKTIF)
            // Ini yang dilihat user (ada Header, Tombol, Grid Gallery, dll).
            // Background putihnya menutupi Layer 0.
            // ============================================================
            Positioned.fill(
              child: Container(
                color: Colors.white, // Nutupin Layer 0
                child: Column(
                  children: [
                    // --- HEADER (FIXED) ---
                    SizedBox(
                      width: 1.sw,
                      height: 290.h,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 20.h,
                            width: 1.sw,
                            child: Image.asset('assets/images/Header Post Page.png', fit: BoxFit.fitWidth),
                          ),
                          Positioned(
                            left: 880.w,
                            top: 162.h,
                            width: 130.w,
                            child: GestureDetector(
                              onTap: _cropAndNavigate, // KLIK NEXT -> JEPRET LAYER 0
                              child: _isProcessing
                                  ? const Center(child: CircularProgressIndicator())
                                  : Image.asset('assets/images/Next_post_button.png', fit: BoxFit.fitWidth),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- KONTEN SCROLLABLE ---
                    Expanded(
                      child: CustomScrollView(
                        physics: _pageScrollPhysics,
                        slivers: [
                          // A. PREVIEW CROP (INTERAKTIF)
                          SliverToBoxAdapter(
                            child: _selectedEntity == null
                                ? SizedBox(
                                    height: 1.sw,
                                    child: const Center(child: CircularProgressIndicator()),
                                  )
                                : AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: 1.sw,
                                    // Visual ikut berubah (Square/Portrait) biar user tau bakal seberapa gedenya
                                    height: _isCoverMode ? 1.sw : 1.25.sw,
                                    color: Colors.white,

                                    child: PostCropPreview(
                                      entity: _selectedEntity!,
                                      isSquareMode: _isCoverMode,
                                      controller: _cropController, // Menggerakkan Layer 0 juga secara otomatis
                                      onToggleMode: () => setState(() => _isCoverMode = !_isCoverMode),
                                      onScrollLock: (isLocked) => setState(
                                        () => _pageScrollPhysics = isLocked
                                            ? const NeverScrollableScrollPhysics()
                                            : const BouncingScrollPhysics(),
                                      ),
                                    ),
                                  ),
                          ),

                          // B. HEADER GALLERY
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              minHeight: 134.h,
                              maxHeight: 134.h,
                              child: Container(
                                color: Colors.white,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      width: 1.sw,
                                      child: Image.asset('assets/images/Header_gallery.png', fit: BoxFit.fitWidth),
                                    ),
                                    // ... (Kode Dropdown Sort Sama Saja) ...
                                    Positioned(
                                      left: 93.w,
                                      top: 35.h,
                                      child: PopupMenuButton<dynamic>(
                                        offset: Offset(140.w, 50.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                                        color: Colors.white,
                                        elevation: 4,
                                        onOpened: () => setState(() => _isMenuOpen = true),
                                        onCanceled: () => setState(() => _isMenuOpen = false),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'newest',
                                            height: 35.h,
                                            child: Text("Oldest", style: TextStyle(fontSize: 35.sp)),
                                          ),
                                          PopupMenuItem(
                                            value: 'oldest',
                                            height: 35.h,
                                            child: Text("Newest", style: TextStyle(fontSize: 35.sp)),
                                          ),
                                          const PopupMenuDivider(),
                                          ..._albumList.map(
                                            (album) => PopupMenuItem(
                                              value: album,
                                              height: 35.h,
                                              child: Text(album.name, style: TextStyle(fontSize: 35.sp)),
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          setState(() => _isMenuOpen = false);
                                          if (value == 'newest') {
                                            setState(() => _isNewestFirst = true);
                                            _loadPhotosFromCurrentAlbum();
                                          } else if (value == 'oldest') {
                                            setState(() => _isNewestFirst = false);
                                            _loadPhotosFromCurrentAlbum();
                                          } else if (value is AssetPathEntity) {
                                            setState(() => _currentAlbum = value);
                                            _loadPhotosFromCurrentAlbum();
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Text(
                                              _currentAlbum?.name ?? "Recent",
                                              style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                                            ),
                                            Icon(
                                              _isMenuOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                              size: 40.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // C. GRID GALLERY
                          SliverGrid(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final asset = _mediaList[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedEntity = asset;
                                    _cropController.value = Matrix4.identity(); // Reset Zoom saat ganti foto
                                  });
                                },
                                child: AssetEntityImage(
                                  asset,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize.square(200),
                                  fit: BoxFit.cover,
                                ),
                              );
                            }, childCount: _mediaList.length),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 2.w,
                              mainAxisSpacing: 2.h,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 270.h)),
                        ],
                      ),
                    ),
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  _StickyHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);
  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => true;
}
