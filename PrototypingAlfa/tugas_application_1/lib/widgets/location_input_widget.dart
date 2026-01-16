import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; // 🔥 BUTUH INI BUAT NGINTIP LINK

class LocationInputWidget extends StatefulWidget {
  final Function(String) onLocationChanged;

  const LocationInputWidget({super.key, required this.onLocationChanged});

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final MapController _mapController = MapController(); // 🔥 PENGENDALI PETA

  String? _savedLink;
  bool _isEditing = false;

  // Default Monas (Buat start awal aja)
  LatLng _currentCoords = LatLng(-6.175392, 106.827153);
  bool _isLoadingMap = false; // Loading indicator pas lagi nyari koordinat

  @override
  void dispose() {
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- 🔥 LOGIC SAKTI: EXTRACT KOORDINAT DARI LINK ---
  Future<void> _extractCoordinates(String shortUrl) async {
    setState(() => _isLoadingMap = true);

    try {
      final client = http.Client();
      var response = await client.get(Uri.parse(shortUrl));

      // Ambil URL hasil redirect (Long URL)
      String longUrl = response.request?.url.toString() ?? shortUrl;
      print("🔍 Link Asli: $longUrl"); // Debug: Lihat link aslinya di console

      // 🛠️ STRATEGI 1: Cari pola @lat,lng (Desktop Standard)
      // Contoh: @-6.175,106.827
      RegExp regExp1 = RegExp(r'@([-0-9.]+),([-0-9.]+)');

      // 🛠️ STRATEGI 2: Cari pola !3d...!4d (Format Data/Place)
      // Contoh: !3d-7.887!4d112.523
      RegExp regExp2 = RegExp(r'!3d([-0-9.]+)!4d([-0-9.]+)');

      // 🛠️ STRATEGI 3: Cari pola query q=lat,lng or ll=lat,lng
      // Contoh: q=-6.175,106.827
      RegExp regExp3 = RegExp(r'[?&](?:q|ll)=([-0-9.]+),([-0-9.]+)');

      double? lat, lng;
      Match? match;

      // Cek Strategi 1
      if ((match = regExp1.firstMatch(longUrl)) != null) {
        print("✅ Strategi 1 Tembus (@)");
        lat = double.parse(match!.group(1)!);
        lng = double.parse(match.group(2)!);
      }
      // Cek Strategi 2
      else if ((match = regExp2.firstMatch(longUrl)) != null) {
        print("✅ Strategi 2 Tembus (!3d!4d)");
        lat = double.parse(match!.group(1)!);
        lng = double.parse(match.group(2)!);
      }
      // Cek Strategi 3
      else if ((match = regExp3.firstMatch(longUrl)) != null) {
        print("✅ Strategi 3 Tembus (Query)");
        lat = double.parse(match!.group(1)!);
        lng = double.parse(match.group(2)!);
      }

      if (lat != null && lng != null) {
        setState(() {
          _currentCoords = LatLng(lat!, lng!);
          _isLoadingMap = false;
        });

        // Pindahkan Peta
        _mapController.move(_currentCoords, 15.0);
        print("📍 Koordinat Fix: $lat, $lng");
      } else {
        print("❌ Gagal Deteksi Koordinat di Link ini.");
        setState(() => _isLoadingMap = false);
      }
    } catch (e) {
      print("Error extracting coords: $e");
      setState(() => _isLoadingMap = false);
    }
  }

  void _saveLink() {
    if (_controller.text.isNotEmpty) {
      String inputLink = _controller.text;
      setState(() {
        _savedLink = inputLink;
        _isEditing = false;
      });

      widget.onLocationChanged(_savedLink!);

      // 🔥 JALANKAN DETEKTIF KOORDINAT
      _extractCoordinates(inputLink);
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      if (_savedLink != null) {
        _controller.text = _savedLink!;
      }
    });
  }

  Future<void> _launchMaps() async {
    if (_savedLink == null) return;
    final Uri url = Uri.parse(_savedLink!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Could not launch $_savedLink");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditingState();
    } else if (_savedLink != null && _savedLink!.isNotEmpty) {
      return _buildPreviewState();
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 40.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Insert Google maps link here",
              style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.location_on, color: Colors.grey, size: 50.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    return GestureDetector(
      onTap: _launchMaps,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            // KOTAK PETA MINI
            ClipRRect(
              borderRadius: BorderRadius.circular(40.r),
              child: SizedBox(
                width: 200.w,
                height: 200.w,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController, // 🔥 PASANG CONTROLLER
                      options: MapOptions(
                        initialCenter: _currentCoords, // 🔥 PAKE KOORDINAT HASIL SCAN
                        initialZoom: 18.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.prototyping.alfa',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentCoords, // 🔥 MARKER IKUT PINDAH
                              width: 80.w,
                              height: 80.w,
                              child: Icon(Icons.location_on, color: Colors.red, size: 60.sp),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // LOADING OVERLAY (Kalau lagi nyari koordinat)
                    if (_isLoadingMap)
                      Container(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 30.w),

            Expanded(
              child: Text(
                _savedLink!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.blue, fontSize: 36.sp, decoration: TextDecoration.underline),
              ),
            ),

            SizedBox(width: 20.w),

            GestureDetector(
              onTap: _startEditing,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(30.r)),
                child: Text(
                  "Edit",
                  style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(fontSize: 40.sp, color: Colors.blue),
              decoration: InputDecoration(
                hintText: "Paste link here...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 36.sp),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _saveLink(),
            ),
          ),
          GestureDetector(
            onTap: _saveLink,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 20.h),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(50.r)),
              child: Text(
                "Save",
                style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
