import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart'; // Pastikan punya file config.dart isinya baseUrl

// Model User sesuai respon Server Python
class UserStub {
  final int id;
  final String username;
  final String fullName;

  UserStub(this.id, this.username, this.fullName);

  // Helper buat ubah JSON dari server jadi Object
  factory UserStub.fromJson(Map<String, dynamic> json) {
    return UserStub(
      json['id'],
      json['username'],
      json['fullName'] ?? json['username'], // Fallback ke username kalo fullname kosong
    );
  }
}

class TagSearchPage extends StatefulWidget {
  final List<UserStub> alreadyTagged;

  const TagSearchPage({super.key, required this.alreadyTagged});

  @override
  State<TagSearchPage> createState() => _TagSearchPageState();
}

class _TagSearchPageState extends State<TagSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<UserStub> _searchResults = [];
  List<UserStub> _selectedUsers = [];
  bool _isLoading = false;
  Timer? _debounce; // Biar gak nembak server tiap ngetik 1 huruf

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.alreadyTagged);
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Matikan timer kalo keluar halaman
    super.dispose();
  }

  // --- FUNGSI CARI KE SERVER ---
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil API: GET /search_users?query=bintang
      final url = Uri.parse("${Config.baseUrl}/search_users?query=$query");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.map((e) => UserStub.fromJson(e)).toList();
        });
      } else {
        print("Gagal search: ${response.statusCode}");
      }
    } catch (e) {
      print("Error search: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Logika Ngetik (Debounce)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Tunggu 500ms setelah user berhenti ngetik, baru cari ke server
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query);
    });
  }

  void _toggleSelection(UserStub user) {
    setState(() {
      // Cek pake ID (karena ID itu unik)
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tag People",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue, size: 30),
            onPressed: () {
              Navigator.pop(context, _selectedUsers);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged, // Pake debounce
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search user (ex: bintang)...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 2. LOADING INDICATOR
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),

          // 3. LIST USER
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty && !_isLoading
                ? const Center(child: Text("User tidak ditemukan"))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedUsers.any((u) => u.id == user.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.fullName),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(Icons.circle_outlined, color: Colors.grey),
                        onTap: () => _toggleSelection(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
