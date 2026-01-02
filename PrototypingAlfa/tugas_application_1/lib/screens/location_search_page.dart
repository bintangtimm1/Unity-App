import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce; // Biar gak nembak API tiap milidetik
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // 🔥 FUNGSI CARI KE BACKEND
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Tunggu 500ms setelah user berhenti ngetik, baru request (Hemat Server)
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Nembak API yang udah King buat
        final response = await http.get(Uri.parse("${Config.baseUrl}/search_locations?query=$query"));

        if (response.statusCode == 200) {
          setState(() {
            _searchResults = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error search location: $e");
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black, size: 50.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Location",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // INPUT SEARCH
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
            child: TextField(
              controller: _searchController,
              autofocus: true, // Langsung muncul keyboard
              onChanged: _onSearchChanged,
              style: TextStyle(fontSize: 35.sp),
              decoration: InputDecoration(
                hintText: "Search city (e.g. Jakarta, Tokyo)",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 40.sp, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(vertical: 25.h),
              ),
            ),
          ),

          // HASIL SEARCH
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final loc = _searchResults[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
                        leading: Container(
                          padding: EdgeInsets.all(15.w),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.location_on, color: Colors.black, size: 40.sp),
                        ),
                        title: Text(
                          loc['location_name'], // Sesuai output API Python King
                          style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          // 🔥 KEMBALIKAN DATA KE HALAMAN SEBELAH
                          Navigator.pop(context, loc['location_name']);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
