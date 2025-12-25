import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // Panggil API Admin yang baru kita buat
      final response = await http.get(Uri.parse('${Config.baseUrl}/admin/get_users'));
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTier(int userId, String tier) async {
    await http.post(
      Uri.parse('${Config.baseUrl}/admin/update_tier'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "tier": tier}),
    );
    _fetchUsers(); // Refresh data
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User jadi $tier!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ADMIN DASHBOARD 🛠️"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['profile_pic_url'] != "" ? NetworkImage(user['profile_pic_url']) : null,
                      child: user['profile_pic_url'] == "" ? Text(user['username'][0]) : null,
                    ),
                    title: Text("${user['username']} (${user['tier']})"),
                    subtitle: Text(user['email']),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _updateTier(user['id'], value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'regular', child: Text("Regular (Polos)")),
                        const PopupMenuItem(value: 'blue', child: Text("Blue (Verified)")),
                        const PopupMenuItem(value: 'gold', child: Text("Gold (Sultan)")),
                      ],
                      icon: const Icon(Icons.edit, color: Colors.blue),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
