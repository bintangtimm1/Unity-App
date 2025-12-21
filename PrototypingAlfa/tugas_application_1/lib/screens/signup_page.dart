import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // --- NEW: ERROR MESSAGE ---
  String? _errorMessage;

  // --- CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- NEW: FOCUS NODES (Buat Lift) ---
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  // --- NEW: DETEKSI SEDANG NGETIK (Cek 4 Kolom) ---
  bool get _isTyping => _emailFocus.hasFocus || _userFocus.hasFocus || _passFocus.hasFocus || _confirmFocus.hasFocus;

  // --- NEW: OFFSET (Posisi Layar) ---
  double _yOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // Pasang pendengar di semua kolom
    _emailFocus.addListener(_updateOffset);
    _userFocus.addListener(_updateOffset);
    _passFocus.addListener(_updateOffset);
    _confirmFocus.addListener(_updateOffset);
  }

  @override
  void dispose() {
    // Wajib bersih-bersih memori
    _emailFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // --- LOGIKA LIFT / ELEVATOR ---
  // Makin bawah kolomnya, makin tinggi layarnya naik
  void _updateOffset() {
    setState(() {
      if (_emailFocus.hasFocus) {
        _yOffset = -360.0; // Naik dikit
      } else if (_userFocus.hasFocus) {
        _yOffset = -360.0;
      } else if (_passFocus.hasFocus) {
        _yOffset = -360.0;
      } else if (_confirmFocus.hasFocus) {
        _yOffset = -360.0; // Naik tinggi banget
      } else {
        _yOffset = 0.0; // Balik normal
      }
    });
  }

  // --- FUNGSI REGISTER ---
  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus(); // Tutup keyboard

    // 1. Reset Error
    setState(() {
      _errorMessage = null;
    });

    // 2. Validasi Input Kosong
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Semua kolom harus diisi!";
      });
      return;
    }

    // 3. Validasi Password Match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Password tidak sama!";
      });
      return;
    }

    // 4. Validasi Checkbox
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
        print("Sukses: ${response.body}");
        if (mounted) {
          // Sukses -> Langsung lempar ke Login Page
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Registrasi Berhasil! Silakan Login.")));
        }
      } else {
        print("Gagal: ${response.body}");
        if (mounted) {
          setState(() {
            // Coba ambil pesan error dari server kalau ada, atau default message
            _errorMessage = "Gagal daftar. Username/Email sudah dipakai.";
          });
        }
      }
    } catch (e) {
      print("Error Koneksi: $e");
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

  // Helper untuk membersihkan error saat ngetik
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
      resizeToAvoidBottomInset: false, // JANGAN GEPENG!

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 1080,
              height: 2424,

              // ANIMASI LIFT
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _yOffset, 0),

                child: Stack(
                  children: [
                    // Background
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 1080,
                      child: Image.asset('assets/images/Signup_background.png', fit: BoxFit.fill),
                    ),

                    // --- TITLE TEXT (ANIMATED) ---
                    // Naik dikit kalau ada error biar gak ketabrak
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 81,
                      top: _errorMessage != null ? 620 : 690, // Naik dari 690 ke 620
                      width: 424,
                      child: Image.asset('assets/images/Sign Up text.png', fit: BoxFit.fill),
                    ),

                    // --- ERROR MESSAGE (NEW) ---
                    if (_errorMessage != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 860, // Posisi di atas Email (927)
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 35, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // --- EMAIL INPUT ---
                    Positioned(
                      left: 94,
                      top: 927,
                      width: 904,
                      height: 111,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                          // Merah kalau error
                          border: Border.all(
                            color: _errorMessage != null ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50.0),
                          child: TextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            onChanged: _clearError,
                            style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.w400),
                            decoration: InputDecoration(
                              hintText: "E-mail",
                              hintStyle: TextStyle(fontSize: 40, color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- USERNAME INPUT ---
                    Positioned(
                      left: 88,
                      top: 1075,
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
                            onChanged: _clearError,
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

                    // --- PASSWORD INPUT ---
                    Positioned(
                      left: 88,
                      top: 1223,
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
                            onChanged: _clearError,
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

                    // --- CONFIRM PASSWORD INPUT ---
                    Positioned(
                      left: 88,
                      top: 1371,
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
                            controller: _confirmPasswordController,
                            focusNode: _confirmFocus,
                            onChanged: _clearError,
                            obscureText: _isObscured1,
                            style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.w400),
                            decoration: InputDecoration(
                              hintText: "Confirm Password",
                              hintStyle: TextStyle(fontSize: 40, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: IconButton(
                                  iconSize: 40,
                                  icon: Icon(
                                    _isObscured1 ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured1 = !_isObscured1;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- CHECKBOX 1 (S&K) ---
                    Positioned(
                      left: 113,
                      top: 1519,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked1 = !_isChecked1;
                            if (_isChecked1 && _isChecked) _errorMessage = null; // Clear error kalau udah centang
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _isChecked1 ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  // Merah kalau error checkbox
                                  color: (_errorMessage != null && !_isChecked1) ? Colors.red : Colors.black,
                                  width: 4,
                                ),
                              ),
                              child: _isChecked1 ? const Icon(Icons.check, size: 40, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 20),
                            const Text(
                              "I agree to the Terms of Service and Privacy Policy.",
                              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- CHECKBOX 2 (Guidelines) ---
                    Positioned(
                      left: 113,
                      top: 1576,
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
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _isChecked ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (_errorMessage != null && !_isChecked) ? Colors.red : Colors.black,
                                  width: 4,
                                ),
                              ),
                              child: _isChecked ? const Icon(Icons.check, size: 40, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 20),
                            const Text(
                              "I agree to the Community Guidelines.",
                              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- TOMBOL CREATE ACCOUNT ---
                    Positioned(
                      left: 94,
                      top: 1656,
                      width: 904,
                      height: 111,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _registerUser,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Image.asset('assets/images/Create Account Button.png', fit: BoxFit.contain),
                      ),
                    ),

                    // Sign Up Another (Or)
                    Positioned(
                      left: 94,
                      top: 1834,
                      width: 904,
                      child: Image.asset('assets/images/Sign Up Another.png', fit: BoxFit.fill),
                    ),

                    // Already Have Account (Ke Login)
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

                    Positioned(
                      top: 360,
                      left: 0,
                      width: 1080,
                      height: 500, // Tinggi area fade (bisa disesuaikan)
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
      ),
    );
  }
}
