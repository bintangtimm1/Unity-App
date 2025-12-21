import 'package:flutter/material.dart';
import 'package:tugas_application_1/screens/main_screen.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';
// import 'screens/add_post_page.dart'; // Buka ini kalau mau pakai Pilihan B

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sosmed App',
      theme: ThemeData(primarySwatch: Colors.blue),

      // Login Page
      //home: const LoginPage(),

      // Main Page
      home: const MainScreen(username: "Centaury (Dev)", userId: 1),

      //Profile Page
      //home: ProfilePage(userId: 1),
    );
  }
}
