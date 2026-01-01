import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. WAJIB IMPORT INI
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/login_page.dart';
import 'screens/main_screen.dart';
import 'screens/admin_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
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

          // Main Page user
          //home: const MainScreen(username: "Centaury (Dev)", userId: 1),
          home: const MainScreen(username: "Photoshop (Dev)", userId: 3),
          //home: const MainScreen(username: "Illustrator (Dev)", userId: 5),

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
