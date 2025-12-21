import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signup_page.dart';
import 'main_screen.dart';
import '../config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- VARIABLES ---
  bool _isObscured = true;
  bool _isChecked = false;
  bool _isLoading = false;
  String? _errorMessage;

  // --- CONTROLLERS & FOCUS ---
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  // --- POSISI LIFT ---
  double _yOffset = 0.0;

  // --- NEW: DETEKSI SEDANG NGETIK ---
  // Berguna untuk memunculkan fade putih
  bool get _isTyping => _userFocus.hasFocus || _passFocus.hasFocus;

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(_updateOffset);
    _passFocus.addListener(_updateOffset);
  }

  @override
  void dispose() {
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _updateOffset() {
    setState(() {
      if (_userFocus.hasFocus) {
        _yOffset = -450.0;
      } else if (_passFocus.hasFocus) {
        _yOffset = -600.0;
      } else {
        _yOffset = 0.0;
      }
    });
  }

  // --- FUNGSI LOGIN (Sama seperti sebelumnya) ---
  Future<void> _loginUser() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
    });

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Username dan Password harus diisi!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    String url = "${Config.baseUrl}/login";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": _usernameController.text, "password": _passwordController.text}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(username: data['username'] ?? "User", userId: data['user_id']),
            ),
          );
        }
      } else {
        if (mounted)
          setState(() {
            _errorMessage = "Username atau Password salah!";
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = "Gagal konek ke Server!";
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 1080,
              height: 2424,

              // --- STACK LUAR (STATIS) ---
              child: Stack(
                children: [
                  // 1. KONTEN YANG BERGERAK (LIFT/ELEVATOR)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(0, _yOffset, 0),
                    child: Stack(
                      children: [
                        // Header Logo
                        Positioned(
                          left: 0,
                          top: 0,
                          width: 1080,
                          child: Image.asset('assets/images/HeaderLogo_login_page.png', fit: BoxFit.fill),
                        ),

                        // Login Text (Animated Position)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: 38,
                          top: _errorMessage != null ? 1000 : 1076,
                          width: 424,
                          child: Image.asset('assets/images/Login_text.png', fit: BoxFit.fill),
                        ),

                        // Error Message
                        if (_errorMessage != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 1250,
                            child: Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 35, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                        // Username Input
                        Positioned(
                          left: 88,
                          top: 1310,
                          width: 904,
                          height: 111,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: _errorMessage != null ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50.0),
                              child: TextField(
                                controller: _usernameController,
                                focusNode: _userFocus,
                                onChanged: (value) {
                                  if (_errorMessage != null) setState(() => _errorMessage = null);
                                },
                                style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.w400),
                                decoration: InputDecoration(
                                  hintText: "Username",
                                  hintStyle: TextStyle(fontSize: 40, color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Password Input
                        Positioned(
                          left: 88,
                          top: 1450,
                          width: 904,
                          height: 111,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: _errorMessage != null ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50.0),
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passFocus,
                                onChanged: (value) {
                                  if (_errorMessage != null) setState(() => _errorMessage = null);
                                },
                                obscureText: _isObscured,
                                style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.w400),
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: TextStyle(fontSize: 40, color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: IconButton(
                                      iconSize: 40,
                                      icon: Icon(
                                        _isObscured ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isObscured = !_isObscured;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Check Box
                        Positioned(
                          left: 115,
                          top: 1580,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isChecked = !_isChecked;
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _isChecked ? Colors.black : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 4),
                                  ),
                                  child: _isChecked ? const Icon(Icons.check, size: 40, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 20),
                                const Text(
                                  "Remember me",
                                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.w500, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Login Button
                        Positioned(
                          left: 88,
                          top: 1658,
                          width: 904,
                          height: 111,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _loginUser,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : Image.asset('assets/images/Login_button.png', fit: BoxFit.contain),
                          ),
                        ),

                        // Forgot Password
                        Positioned(
                          left: 382,
                          top: 1808,
                          width: 315,
                          child: Image.asset('assets/images/Forgot_Password.png', fit: BoxFit.fill),
                        ),

                        // Social Media
                        Positioned(
                          left: 92,
                          top: 1895,
                          width: 900,
                          child: Image.asset('assets/images/login_social_media.png', fit: BoxFit.fill),
                        ),

                        // Dont Have Account
                        Positioned(
                          left: 260,
                          top: 2131,
                          width: 560,
                          height: 49,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 300),
                                  pageBuilder: (context, animation, secondaryAnimation) => const SignupPage(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                      FadeTransition(opacity: animation, child: child),
                                ),
                              );
                            },
                            child: Image.asset('assets/images/dont_have_account.png', fit: BoxFit.contain),
                          ),
                        ),

                        // S&K
                        Positioned(
                          left: 139,
                          top: 2194,
                          width: 801,
                          child: Image.asset('assets/images/S%K.png', fit: BoxFit.fill),
                        ),
                      ],
                    ),
                  ),

                  // --- 2. LAYER GRADASI PUTIH (STATIS DI ATAS) ---
                  // Ini yang bikin efek fade di area kamera
                  Positioned(
                    top: 0,
                    left: 0,
                    width: 1080,
                    height: 700, // Tinggi area fade (bisa disesuaikan)
                    child: IgnorePointer(
                      // Biar klik tembus ke bawahnya
                      child: AnimatedOpacity(
                        // Muncul cuma pas lagi ngetik (_isTyping = true)
                        opacity: _isTyping ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(1.0), // Putih Solid di paling atas
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.0), // Transparan di bawah
                              ],
                              stops: const [0.0, 0.3, 1.0], // Titik gradasinya biar halus
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
