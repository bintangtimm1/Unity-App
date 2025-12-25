import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. WAJIB IMPORT INI
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/login_page.dart';
import 'screens/main_screen.dart';
import 'screens/admin_dashboard.dart';

void main() {
  // 2. TAMBAHKAN MANTRA INI
  WidgetsFlutterBinding.ensureInitialized();

  // Mantra biar aplikasi tembus sampai belakang Status Bar & Nav Bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Bikin Nav Bar HP & Status Bar jadi Bening/Transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Atas bening
      systemNavigationBarColor: Colors.white, // Bawah bening
      systemNavigationBarIconBrightness: Brightness.dark, // Ikon tombol HP jadi gelap
      statusBarIconBrightness: Brightness.dark, // Ikon baterai/jam jadi gelap
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 2424),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sosmed App',
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
          // Login Page
          //home: const LoginPage(),

          // Main Page
          //home: const MainScreen(username: "Centaury (Dev)", userId: 1),
          home: const MainScreen(username: "Photoshop (Dev)", userId: 3),

          //Profile Page
          //home: ProfilePage(userId: 1),

          //Admin Page
          //home: const DevLauncherPage(),
        );
      },
    );
  }
}

class DevLauncherPage extends StatelessWidget {
  const DevLauncherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "👑 PROJECT LAUNCHER",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),

            // TOMBOL MASUK APLIKASI USER
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              icon: const Icon(Icons.smartphone),
              label: const Text("BUKA APLIKASI UTAMA"),
            ),

            const SizedBox(height: 20),

            // TOMBOL MASUK ADMIN PANEL (LUAR APLIKASI)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text("BUKA ADMIN DASHBOARD"),
            ),
          ],
        ),
      ),
    );
  }
}
