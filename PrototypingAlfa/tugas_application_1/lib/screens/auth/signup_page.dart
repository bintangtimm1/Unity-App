import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_page.dart';
import '../../config.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with WidgetsBindingObserver {
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

  // --- FOCUS NODES ---
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool get _isTyping => _emailFocus.hasFocus || _userFocus.hasFocus || _passFocus.hasFocus || _confirmFocus.hasFocus;

  double _yOffset = 0.0;
  double _lastBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emailFocus.addListener(_updateOffset);
    _userFocus.addListener(_updateOffset);
    _passFocus.addListener(_updateOffset);
    _confirmFocus.addListener(_updateOffset);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = View.of(context).viewInsets.bottom;

    // 🔥 LOGIKA ANTI-DROP:
    // Hanya turunkan UI jika keyboard benar-benar menutup (0.0) DARI posisi terbuka
    if (bottomInset == 0.0 && _lastBottomInset > 0.0) {
      if (_yOffset != 0.0) {
        setState(() {
          _yOffset = 0.0;
        });
        // Lepas fokus HANYA jika keyboard tutup manual (Back Button / Tap Luar)
        FocusScope.of(context).unfocus();
      }
    }
    _lastBottomInset = bottomInset;
  }

  void _updateOffset() {
    setState(() {
      if (_emailFocus.hasFocus) {
        _yOffset = -360.h;
      } else if (_userFocus.hasFocus) {
        _yOffset = -360.h;
      } else if (_passFocus.hasFocus) {
        _yOffset = -360.h;
      } else if (_confirmFocus.hasFocus) {
        _yOffset = -450.h;
      } else {
        _yOffset = 0.0;
      }
    });
  }

  // --- FUNGSI REGISTER ---
  Future<void> _registerUser() async {
    // ❌ JANGAN ADA FocusScope.of(context).unfocus() DISINI!
    // Biarkan keyboard tetap nyala selama proses cek error & loading.

    setState(() => _errorMessage = null);

    // 1. CEK KOSONG
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = "Semua kolom harus diisi!");
      return;
    }

    String inputUsername = _usernameController.text;

    // 2. VALIDASI USERNAME
    if (inputUsername.contains(' ')) {
      setState(() => _errorMessage = "Username tidak boleh ada spasi!");
      return;
    }
    if (inputUsername != inputUsername.toLowerCase()) {
      setState(() => _errorMessage = "Username harus huruf kecil semua!");
      return;
    }
    final validCharacters = RegExp(r'^[a-z0-9._]+$');
    if (!validCharacters.hasMatch(inputUsername)) {
      setState(() => _errorMessage = "Hanya huruf, angka, titik, dan underscore!");
      return;
    }

    // 3. VALIDASI PASSWORD
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Password tidak sama!");
      return;
    }

    // 4. VALIDASI S&K
    if (!_isChecked || !_isChecked1) {
      setState(() => _errorMessage = "Setujui S&K dan Guidelines dulu!");
      return;
    }

    // 🔥 HAPUS UNFOCUS DISINI JUGA!
    // Biarkan keyboard tetap nyala saat loading

    setState(() => _isLoading = true);

    String url = "${Config.baseUrl}/register";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          // Kalau sukses, baru pindah halaman (Context hancur, keyboard otomatis beres)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Registrasi Berhasil! Silakan Login.")));
        }
      } else {
        // Kalau Gagal (Server Error), keyboard TETAP NYALA, Error Muncul
        if (mounted) setState(() => _errorMessage = "Gagal daftar. Username/Email sudah dipakai.");
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Gagal konek ke Server!");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validateUsernameRealTime(String value) {
    String? newError;
    if (value.isNotEmpty) {
      if (value.contains(' ')) {
        newError = "Username tidak boleh ada spasi!";
      } else if (value != value.toLowerCase()) {
        newError = "Gunakan huruf kecil semua!";
      } else {
        final validCharacters = RegExp(r'^[a-z0-9._]+$');
        if (!validCharacters.hasMatch(value)) {
          newError = "Hanya huruf, angka, titik, & underscore!";
        }
      }
    }

    if (_errorMessage != newError) {
      setState(() {
        _errorMessage = newError;
      });
    }
  }

  void _clearError(String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _yOffset, 0),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 1080.w,
                      child: Image.asset('assets/images/Signup_background.png', fit: BoxFit.fitWidth),
                    ),

                    // HEADER TEXT (NAIK TURUN IKUT ERROR)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 81.w,
                      top: _errorMessage != null ? 620.h : 690.h,
                      width: 424.w,
                      child: Image.asset('assets/images/Sign Up text.png', fit: BoxFit.fill),
                    ),

                    // 🔥 ERROR MESSAGE (FIXED POSITION - SELALU ADA)
                    // Kita hapus "if (_errorMessage != null)" biar urutan Stack stabil
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 860.h,
                      child: Center(
                        child: Text(
                          _errorMessage ?? "", // Kalau null, tampilkan string kosong
                          style: TextStyle(color: Colors.red, fontSize: 35.sp, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // EMAIL
                    Positioned(
                      left: 94.w,
                      top: 927.h,
                      width: 904.w,
                      height: 111.h,
                      child: AuthTextField(
                        key: const ValueKey('email_field'),
                        controller: _emailController,
                        focusNode: _emailFocus,
                        hintText: "E-mail",
                        hasError: _errorMessage != null,
                        defaultOnChanged: _clearError,
                      ),
                    ),

                    // USERNAME
                    Positioned(
                      left: 88.w,
                      top: 1075.h,
                      width: 904.w,
                      height: 111.h,
                      child: AuthTextField(
                        key: const ValueKey('username_field'),
                        controller: _usernameController,
                        focusNode: _userFocus,
                        hintText: "username",
                        hasError: _errorMessage != null,
                        customOnChanged: _validateUsernameRealTime,
                      ),
                    ),

                    // PASSWORD
                    Positioned(
                      left: 88.w,
                      top: 1223.h,
                      width: 904.w,
                      height: 111.h,
                      child: AuthTextField(
                        key: const ValueKey('pass_field'),
                        controller: _passwordController,
                        focusNode: _passFocus,
                        hintText: "Password",
                        hasError: _errorMessage != null,
                        isPassword: true,
                        isObscured: _isObscured,
                        onToggleVisibility: () => setState(() => _isObscured = !_isObscured),
                        defaultOnChanged: _clearError,
                      ),
                    ),

                    // CONFIRM PASSWORD
                    Positioned(
                      left: 88.w,
                      top: 1371.h,
                      width: 904.w,
                      height: 111.h,
                      child: AuthTextField(
                        key: const ValueKey('confirm_field'),
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        hintText: "Confirm Password",
                        hasError: _errorMessage != null,
                        isPassword: true,
                        isObscured: _isObscured1,
                        onToggleVisibility: () => setState(() => _isObscured1 = !_isObscured1),
                        defaultOnChanged: _clearError,
                      ),
                    ),

                    // CHECKBOXES
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
                              "I agree to the Terms of Service and Privacy Policy.",
                              style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 113.w,
                      top: 1590.h,
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

                    // BUTTONS
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
                    Positioned(
                      left: 94.w,
                      top: 1860.h,
                      width: 904.w,
                      child: Image.asset('assets/images/Sign Up Another.png', fit: BoxFit.fill),
                    ),
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
              // GRADIENT OVERLAY
              Positioned(
                top: 0,
                left: 0,
                width: 1.sw,
                height: 500.h,
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

// 🔥 WIDGET TEXTFIELD (TETAP SAMA)
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool hasError;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleVisibility;
  final Function(String)? customOnChanged;
  final Function(String)? defaultOnChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.hasError = false,
    this.isPassword = false,
    this.isObscured = false,
    this.onToggleVisibility,
    this.customOnChanged,
    this.defaultOnChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          onChanged: customOnChanged ?? defaultOnChanged,
          obscureText: isObscured,
          style: TextStyle(fontSize: 40.sp, color: Colors.black, fontWeight: FontWeight.w400, height: 1.0),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 40.sp, color: Colors.grey.shade400),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 30.h),
            suffixIcon: isPassword
                ? Padding(
                    padding: EdgeInsets.only(left: 50.w),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
