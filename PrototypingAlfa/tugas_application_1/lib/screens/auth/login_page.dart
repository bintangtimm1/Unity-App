import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'signup_page.dart';
import '../main_screen.dart';
import '../../config.dart';

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

  // --- POSISI LIFT (OFFSETS) ---
  double _yOffset = 0.0;

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
        _yOffset = -450.h;
      } else if (_passFocus.hasFocus) {
        _yOffset = -600.h;
      } else {
        _yOffset = 0.0;
      }
    });
  }

  // --- FUNGSI LOGIN ---
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
      String rawUsername = _usernameController.text.trim();

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        // Kirim rawUsername
        body: jsonEncode({"username": rawUsername, "password": _passwordController.text}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MainScreen(username: data['display_name'] ?? data['username'] ?? "User", userId: data['user_id']),
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
        child: SizedBox(
          width: 1.sw,
          height: 1.sh,
          child: Stack(
            children: [
              // 1. KONTEN YANG BERGERAK (LIFT/ELEVATOR)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _yOffset, 0),
                child: Stack(
                  children: [
                    // --- HEADER & LOGO ---
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 1080.w,
                      child: Image.asset('assets/images/HeaderLogo_login_page.png', fit: BoxFit.fitWidth),
                    ),

                    // --- LOGIN TEXT ---
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 38.w,
                      top: _errorMessage != null ? 1000.h : 1076.h,
                      width: 424.w,
                      child: Image.asset('assets/images/Login_text.png', fit: BoxFit.fill),
                    ),

                    // --- ERROR MESSAGE ---
                    if (_errorMessage != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 1250.h,
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 35.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    // --- INPUT USERNAME ---
                    Positioned(
                      left: 88.w,
                      top: 1310.h,
                      width: 904.w,
                      height: 111.h,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60.r),
                          border: Border.all(
                            color: _errorMessage != null ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
                            width: 3.w,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: TextField(
                            controller: _usernameController,
                            focusNode: _userFocus,
                            onChanged: (value) {
                              if (_errorMessage != null) setState(() => _errorMessage = null);
                            },
                            style: TextStyle(
                              fontSize: 40.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                            ),
                            decoration: InputDecoration(
                              hintText: "Username",
                              hintStyle: TextStyle(fontSize: 40.sp, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 30.h),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- INPUT PASSWORD ---
                    Positioned(
                      left: 88.w,
                      top: 1450.h,
                      width: 904.w,
                      height: 111.h,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60.r),
                          border: Border.all(
                            color: _errorMessage != null ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
                            width: 3.w,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passFocus,
                            onChanged: (value) {
                              if (_errorMessage != null) setState(() => _errorMessage = null);
                            },
                            obscureText: _isObscured,
                            style: TextStyle(
                              fontSize: 40.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                            ),
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: TextStyle(fontSize: 40.sp, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 35.h),
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(left: 70.w),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 35.sp,
                                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
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

                    // --- CHECKBOX REMEMBER ME ---
                    Positioned(
                      left: 115.w,
                      top: 1580.h,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked = !_isChecked;
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
                                border: Border.all(color: Colors.black, width: 4.w),
                              ),
                              child: _isChecked ? Icon(Icons.check, size: 40.sp, color: Colors.white) : null,
                            ),
                            SizedBox(width: 20.w),
                            Text(
                              "Remember me",
                              style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- LOGIN BUTTON ---
                    Positioned(
                      left: 88.w,
                      top: 1658.h,
                      width: 904.w,
                      height: 111.h,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _loginUser,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Image.asset('assets/images/Login_button.png', fit: BoxFit.contain),
                      ),
                    ),

                    // --- FORGOT PASSWORD ---
                    Positioned(
                      left: 382.w,
                      top: 1808.h,
                      width: 315.w,
                      child: Image.asset('assets/images/Forgot_Password.png', fit: BoxFit.fill),
                    ),

                    // --- SOCIAL MEDIA ---
                    Positioned(
                      left: 92.w,
                      top: 1895.h,
                      width: 900.w,
                      child: Image.asset('assets/images/login_social_media.png', fit: BoxFit.fill),
                    ),

                    // --- DONT HAVE ACCOUNT ---
                    Positioned(
                      left: 260.w,
                      bottom: 250.h,
                      width: 560.w,
                      height: 49.h,
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

                    // --- S&K / TERMS ---
                    Positioned(
                      left: 139.w,
                      bottom: 180.h,
                      width: 801.w,
                      child: Image.asset('assets/images/S%K.png', fit: BoxFit.fill),
                    ),
                  ],
                ),
              ),

              // --- 2. LAYER GRADASI PUTIH ---
              Positioned(
                top: 0,
                left: 0,
                width: 1.sw,
                height: 700.h,
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
}
