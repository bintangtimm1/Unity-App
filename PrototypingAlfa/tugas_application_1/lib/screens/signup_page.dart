import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Jangan lupa package ini
import 'login_page.dart';
import '../config.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // --- VARIABLES ---
  bool _isObscured = true;
  bool _isObscured1 = true;
  bool _isChecked = false;
  bool _isChecked1 = false;
  bool _isLoading = false;
  String? _errorMessage;

  // --- CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- FOCUS NODES (Buat Lift) ---
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool get _isTyping => _emailFocus.hasFocus || _userFocus.hasFocus || _passFocus.hasFocus || _confirmFocus.hasFocus;

  double _yOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_updateOffset);
    _userFocus.addListener(_updateOffset);
    _passFocus.addListener(_updateOffset);
    _confirmFocus.addListener(_updateOffset);
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // --- LOGIKA LIFT (RESPONSIF) ---
  void _updateOffset() {
    setState(() {
      if (_emailFocus.hasFocus) {
        _yOffset = -360.h;
      } else if (_userFocus.hasFocus) {
        _yOffset = -360.h;
      } else if (_passFocus.hasFocus) {
        _yOffset = -360.h;
      } else if (_confirmFocus.hasFocus) {
        _yOffset = -450.h; // Naik lebih tinggi
      } else {
        _yOffset = 0.0;
      }
    });
  }

  // --- FUNGSI REGISTER ---
  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
    });

    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Semua kolom harus diisi!";
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Password tidak sama!";
      });
      return;
    }

    if (!_isChecked || !_isChecked1) {
      setState(() {
        _errorMessage = "Setujui S&K dan Guidelines dulu!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String url = "${Config.baseUrl}/register";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Registrasi Berhasil! Silakan Login.")));
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Gagal daftar. Username/Email sudah dipakai.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal konek ke Server!";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearError(String value) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
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
        child: SizedBox(
          width: 1.sw,
          height: 1.sh,
          child: Stack(
            children: [
              // 1. KONTEN UTAMA
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _yOffset, 0),
                child: Stack(
                  children: [
                    // --- BACKGROUND ---
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 1080.w,
                      child: Image.asset('assets/images/Signup_background.png', fit: BoxFit.fitWidth),
                    ),

                    // --- TITLE TEXT ---
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 81.w,
                      top: _errorMessage != null ? 620.h : 690.h,
                      width: 424.w,
                      child: Image.asset('assets/images/Sign Up text.png', fit: BoxFit.fill),
                    ),

                    // --- ERROR MESSAGE ---
                    if (_errorMessage != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 860.h,
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 35.sp, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // --- EMAIL INPUT ---
                    Positioned(
                      left: 94.w,
                      top: 927.h,
                      width: 904.w,
                      height: 111.h,
                      child: _buildTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        hintText: "E-mail",
                        hasError: _errorMessage != null,
                      ),
                    ),

                    // --- USERNAME INPUT ---
                    Positioned(
                      left: 88.w,
                      top: 1075.h,
                      width: 904.w,
                      height: 111.h,
                      child: _buildTextField(
                        controller: _usernameController,
                        focusNode: _userFocus,
                        hintText: "Username",
                        hasError: _errorMessage != null,
                      ),
                    ),

                    // --- PASSWORD INPUT ---
                    Positioned(
                      left: 88.w,
                      top: 1223.h,
                      width: 904.w,
                      height: 111.h,
                      child: _buildTextField(
                        controller: _passwordController,
                        focusNode: _passFocus,
                        hintText: "Password",
                        hasError: _errorMessage != null,
                        isPassword: true,
                        isObscured: _isObscured,
                        onToggleVisibility: () => setState(() => _isObscured = !_isObscured),
                      ),
                    ),

                    // --- CONFIRM PASSWORD INPUT ---
                    Positioned(
                      left: 88.w,
                      top: 1371.h,
                      width: 904.w,
                      height: 111.h,
                      child: _buildTextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        hintText: "Confirm Password",
                        hasError: _errorMessage != null,
                        isPassword: true,
                        isObscured: _isObscured1,
                        onToggleVisibility: () => setState(() => _isObscured1 = !_isObscured1),
                      ),
                    ),

                    // --- CHECKBOX 1 (S&K) ---
                    Positioned(
                      left: 113.w,
                      top: 1519.h,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked1 = !_isChecked1;
                            if (_isChecked1 && _isChecked) _errorMessage = null;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                color: _isChecked1 ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: (_errorMessage != null && !_isChecked1) ? Colors.red : Colors.black,
                                  width: 4.w,
                                ),
                              ),
                              child: _isChecked1 ? Icon(Icons.check, size: 40.sp, color: Colors.white) : null,
                            ),
                            SizedBox(width: 20.w),
                            Text(
                              "I agree to the Terms of Service\nand Privacy Policy.",
                              style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- CHECKBOX 2 (Guidelines) ---
                    Positioned(
                      left: 113.w,
                      top: 1610.h,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked = !_isChecked;
                            if (_isChecked1 && _isChecked) _errorMessage = null;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                color: _isChecked ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: (_errorMessage != null && !_isChecked) ? Colors.red : Colors.black,
                                  width: 4.w,
                                ),
                              ),
                              child: _isChecked ? Icon(Icons.check, size: 40.sp, color: Colors.white) : null,
                            ),
                            SizedBox(width: 20.w),
                            Text(
                              "I agree to the Community Guidelines.",
                              style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- TOMBOL CREATE ACCOUNT ---
                    Positioned(
                      left: 94.w,
                      top: 1690.h,
                      width: 904.w,
                      height: 111.h,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _registerUser,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Image.asset('assets/images/Create Account Button.png', fit: BoxFit.contain),
                      ),
                    ),

                    // --- OR SIGNUP WITH ---
                    Positioned(
                      left: 94.w,
                      top: 1860.h,
                      width: 904.w,
                      child: Image.asset('assets/images/Sign Up Another.png', fit: BoxFit.fill),
                    ),

                    // --- ALREADY HAVE ACCOUNT (Jangkar Bawah) ---
                    Positioned(
                      left: 260.w,
                      bottom: 250.h, // Dikunci di bawah biar aman
                      width: 560.w,
                      height: 49.h,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 300),
                              pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        },
                        child: Image.asset('assets/images/Already have account.png', fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. FADE EFFECT LAYER ---
              Positioned(
                top: 0, // Nempel atas
                left: 0,
                width: 1.sw,
                height: 500.h, // Area fade
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isTyping ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(1.0),
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.3, 1.0],
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
    );
  }

  // 🔥 WIDGET PINTAR: TEXTFIELD + CUSTOM ICON 🔥
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    bool hasError = false,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60.r),
        border: Border.all(color: hasError ? Colors.red : const Color.fromARGB(255, 0, 0, 0), width: 3.w),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: _clearError,
          obscureText: isObscured,
          style: TextStyle(fontSize: 40.sp, color: Colors.black, fontWeight: FontWeight.w400, height: 1.0),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 40.sp, color: Colors.grey.shade400),
            border: InputBorder.none,
            // LOGIC CENTER TEXT
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 30.h),

            // LOGIC ICON MEPET KANAN (Custom)
            suffixIcon: isPassword
                ? Padding(
                    // Bisa ganti 0.w kalau mau lebih mepet lagi
                    padding: EdgeInsets.only(left: 50.w),
                    child: IconButton(
                      padding: EdgeInsets.zero, // Hapus padding internal
                      constraints: const BoxConstraints(), // Hapus batasan size default
                      iconSize: 35.sp,
                      icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: onToggleVisibility,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
