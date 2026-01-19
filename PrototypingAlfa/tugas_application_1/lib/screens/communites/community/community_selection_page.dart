import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config.dart';

class CommunitySelectionPage extends StatefulWidget {
  final int userId;
  final int? selectedCommunityId; // ID yang sedang dipilih (biar ada tanda centang)

  const CommunitySelectionPage({super.key, required this.userId, this.selectedCommunityId});

  @override
  State<CommunitySelectionPage> createState() => _CommunitySelectionPageState();
}

class _CommunitySelectionPageState extends State<CommunitySelectionPage> {
  List<dynamic> _communities = [];
  bool _isLoading = true;
  int? _selectedId; // Simpan ID yang dipilih user

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedCommunityId; // Set awal
    _fetchJoinedCommunities();
  }

  // 🔥 FUNGSI FETCH KOMUNITAS YANG SUDAH DI-JOIN
  Future<void> _fetchJoinedCommunities() async {
    try {
      final response = await http.get(Uri.parse("${Config.baseUrl}/get_joined_communities?user_id=${widget.userId}"));

      if (response.statusCode == 200) {
        setState(() {
          _communities = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print("Gagal fetch community: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetch community: $e");
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Balik tanpa update
        ),
        title: const Text(
          "Tag Community",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // TOMBOL SAVE (CENTANG)
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue, size: 30),
            onPressed: () {
              // Cari object komunitas lengkap berdasarkan ID yang dipilih
              Map<String, dynamic>? selectedData;

              // Cek array _communities dulu biar aman
              if (_selectedId != null && _communities.isNotEmpty) {
                try {
                  selectedData = _communities.firstWhere((element) => element['id'] == _selectedId);
                } catch (e) {
                  selectedData = null;
                }
              }
              Navigator.pop(context, {'confirm': true, 'data': selectedData});
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _communities.isEmpty
          ? const Center(child: Text("You haven't joined any community yet."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _communities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comm = _communities[index];
                final bool isSelected = comm['id'] == _selectedId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (comm['icon_url'] != null && comm['icon_url'] != "")
                        ? CachedNetworkImageProvider(comm['icon_url'])
                        : null,
                    child: (comm['icon_url'] == null || comm['icon_url'] == "")
                        ? const Icon(Icons.groups, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    comm['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.blue : Colors.black),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      // Logika Toggle: Kalau diklik lagi, jadi unselect
                      if (_selectedId == comm['id']) {
                        _selectedId = null;
                      } else {
                        _selectedId = comm['id'];
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}
