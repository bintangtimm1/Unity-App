import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../widgets/post_crop_preview.dart';
import 'post_upload_page.dart';
import 'package:http/http.dart' as http;

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
  // ignore: unused_field
  bool _isCoverMode = true;
  List<AssetPathEntity> _albumList = []; // Daftar semua folder (Camera, WA, dll)
  AssetPathEntity? _currentAlbum; // Folder yang sedang aktif sekarang
  bool _isNewestFirst = true;
  bool _isMenuOpen = false;
  File? _finalImageFile;
  ScrollPhysics _pageScrollPhysics = const BouncingScrollPhysics();
  final TransformationController _cropController = TransformationController();

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  // --- FUNGSI 1: AMBIL FOTO ---
  Future<void> _fetchNewMedia() async {
    await PhotoManager.requestPermissionExtend();
    try {
      // 1. Ambil SEMUA Album (hasAll: true artinya termasuk folder "Recent")
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true, // Wajib true biar folder "Semua Foto" muncul
      );

      if (albums.isNotEmpty) {
        // 2. Default-nya pilih album pertama (biasanya Recents)
        _currentAlbum = albums[0];
        _albumList = albums;

        // 3. Load foto dari album yang dipilih
        await _loadPhotosFromCurrentAlbum();
      }
    } catch (e) {
      print("Error load album: $e");
    }
  }

  // Fungsi khusus buat load foto dari album yang sedang aktif (_currentAlbum)
  Future<void> _loadPhotosFromCurrentAlbum() async {
    if (_currentAlbum == null) return;

    // Ambil foto (Default photo_manager selalu ambil dari terbaru)
    List<AssetEntity> photos = await _currentAlbum!.getAssetListPaged(page: 0, size: 100);

    // --- LOGIKA SORTIR ---
    if (!_isNewestFirst) {
      // Kalau user minta Terlama, kita balik urutannya
      photos = photos.reversed.toList();
    }

    setState(() {
      _mediaList = photos;
      if (_mediaList.isNotEmpty) {
        _selectedEntity = _mediaList[0];
      }
    });
  }

  // --- FUNGSI 2: TOMBOL NEXT ---
  // --- FUNGSI TOMBOL NEXT ---
  void _onNextPressed() {
    // Cek: Apakah user sudah memilih foto?
    if (_selectedEntity != null) {
      // Kalau ada, pindah ke halaman Upload
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostUploadPage(
            entity: _selectedEntity!, // Bawa fotonya
            isSquareMode: _isCoverMode,
            cropMatrix: _cropController.value,
            userId: widget.userId, // Bawa status crop-nya
          ),
        ),
      );
    } else {
      // Opsional: Kasih pesan kalau belum pilih foto
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih foto dulu ya!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi tinggi area berdasarkan desain Figma kamu
    // Header Page: 0 - 285
    // Preview Image: 285 - 1365 (Tinggi 1080)
    // Sticky Header (Gallery controls): 1365 - 1499 (Tinggi 134)

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1080,
            height: 2424,
            child: Column(
              children: [
                // ==========================================
                // 1. FIXED APP HEADER (DIAM DI ATAS)
                // ==========================================
                SizedBox(
                  width: 1080,
                  height: 290, // Tinggi header sesuai layout kamu (sebelum preview mulai)
                  child: Stack(
                    children: [
                      // Background Header
                      Positioned(
                        left: 0,
                        top: 20,
                        width: 1080,
                        child: Image.asset('assets/images/Header Post Page.png', fit: BoxFit.fill),
                      ),
                      // Tombol Next
                      Positioned(
                        left: 880,
                        top: 162,
                        width: 130,
                        child: GestureDetector(
                          onTap: _onNextPressed,
                          child: Image.asset('assets/images/Next_post_button.png', fit: BoxFit.fill),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 2. SCROLLABLE AREA (TENGAH & BAWAH)
                // ==========================================
                Expanded(
                  child: CustomScrollView(
                    physics: _pageScrollPhysics, // Efek mantul
                    slivers: [
                      // A. BAGIAN PREVIEW (CROP & ADJUST)
                      SliverToBoxAdapter(
                        child: _selectedEntity == null
                            ? const SizedBox(height: 1080, child: Center(child: CircularProgressIndicator()))
                            : PostCropPreview(
                                entity: _selectedEntity!,
                                isSquareMode: _isCoverMode, // Kirim status mode
                                controller: _cropController,
                                // Callback saat tombol resize diklik
                                onToggleMode: () {
                                  setState(() {
                                    _isCoverMode = !_isCoverMode;
                                  });
                                },

                                // Callback untuk kunci/buka scroll halaman
                                onScrollLock: (isLocked) {
                                  setState(() {
                                    _pageScrollPhysics = isLocked
                                        ? const NeverScrollableScrollPhysics()
                                        : const BouncingScrollPhysics();
                                  });
                                },
                              ),
                      ),
                      // B. STICKY HEADER GALLERY (NEMPEL SAAT SCROLL)
                      SliverPersistentHeader(
                        pinned: true, // INI KUNCINYA AGAR NEMPEL
                        delegate: _StickyHeaderDelegate(
                          minHeight: 134, // Tinggi area header gallery (1499 - 1365)
                          maxHeight: 134,
                          child: Container(
                            color: Colors.white, // Background putih biar nutup gambar pas scroll
                            child: Stack(
                              children: [
                                // Header Gallery BG
                                Positioned(
                                  left: 0,
                                  top: 0, // Reset ke 0 karena ini container baru
                                  width: 1080,
                                  child: Image.asset('assets/images/Header_gallery.png', fit: BoxFit.fill),
                                ),
                                // Sort Button
                                Positioned(
                                  left: 93,
                                  top: 35,
                                  child: PopupMenuButton<dynamic>(
                                    // Ganti GestureDetector jadi ini
                                    offset: const Offset(140, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    color: const Color.fromARGB(255, 255, 255, 255),
                                    elevation: 4,

                                    onOpened: () {
                                      setState(() => _isMenuOpen = true); // Menu Buka -> Panah Bawah
                                    },
                                    onCanceled: () {
                                      setState(() => _isMenuOpen = false); // Batal -> Panah Kanan
                                    },

                                    // ISI MENU (Terbaru, Terlama, Album List)
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        // OPSI 1: TERBARU
                                        PopupMenuItem(
                                          value: 'newest',
                                          height: 35,
                                          child: Row(
                                            children: [
                                              Text(
                                                "Oldest",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: _isNewestFirst ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // OPSI 2: TERLAMA
                                        PopupMenuItem(
                                          value: 'oldest',
                                          height: 35,
                                          child: Row(
                                            children: [
                                              Text(
                                                "Newest",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: !_isNewestFirst ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(height: 10),

                                        // OPSI 3: LIST ALBUM (Looping dari variable)
                                        ..._albumList.map((album) {
                                          return PopupMenuItem(
                                            value: album,
                                            height: 35,
                                            child: Text(
                                              album.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: _currentAlbum == album
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          );
                                        }),
                                      ];
                                    },

                                    // LOGIKA SAAT DIPILIH
                                    onSelected: (value) {
                                      setState(() => _isMenuOpen = false); // Dipilih -> Panah Kanan

                                      // ... Logika lama kamu di sini ...
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

                                    // TAMPILAN TOMBOLNYA (Row text + Icon panah)
                                    child: Row(
                                      // <--- INI ROW YANG TADI, SEKARANG JADI CHILD DARI POPUP
                                      children: [
                                        Text(
                                          _currentAlbum?.name ?? "Recent",
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          _isMenuOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                          size: 40,
                                          color: Colors.black,
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

                      // C. GRID GALLERY (BAWAH)
                      SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final asset = _mediaList[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEntity = asset;
                              });
                            },
                            child: AssetEntityImage(
                              asset,
                              isOriginal: false, // Thumbnail
                              thumbnailSize: const ThumbnailSize.square(200),
                              fit: BoxFit.cover,
                            ),
                          );
                        }, childCount: _mediaList.length),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                      ),

                      // Tambahan space bawah biar enak scrollnya (Opsional)
                      const SliverToBoxAdapter(child: SizedBox(height: 270)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlbumSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) {
        return Container(
          height: 1000, // Tinggi sheet (bisa diatur)
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            children: [
              // Judul Sheet
              Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 30),

              // Daftar Album
              Expanded(
                child: ListView.builder(
                  itemCount: _albumList.length,
                  itemBuilder: (context, index) {
                    final album = _albumList[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      title: Text(
                        album.name, // Nama Album (Camera, WhatsApp, dll)
                        style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w500),
                      ),
                      subtitle: FutureBuilder<int>(
                        future: album.assetCountAsync, // Hitung jumlah foto
                        builder: (context, snapshot) =>
                            Text("${snapshot.data ?? 0} Photos", style: TextStyle(fontSize: 25, color: Colors.grey)),
                      ),
                      onTap: () {
                        // Saat album dipilih:
                        setState(() {
                          _currentAlbum = album; // Ganti album aktif
                        });
                        _loadPhotosFromCurrentAlbum(); // Load foto baru
                        Navigator.pop(context); // Tutup pop-up
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi bikin garis grid tipis
  Widget _buildLine({required bool vertical}) {
    return Container(
      width: vertical ? 1 : double.infinity,
      height: vertical ? double.infinity : 1,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, spreadRadius: 0)],
      ),
    );
  }
}

// --- KELAS PEMBANTU UNTUK STICKY HEADER ---
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
