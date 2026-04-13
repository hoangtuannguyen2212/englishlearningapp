import 'package:flutter/material.dart';
import 'auth_services.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordVisible = false;

  // ==========================================
  // HÀM XỬ LÝ ĐĂNG NHẬP / ĐĂNG KÝ
  // ==========================================
  void _submitAuth() async {
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    String result;
    if (isLogin) {
      result = await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      result = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );
    }

    setState(() => isLoading = false);

    if (result == "Successful") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogin ? '✅ Sign in successful!' : '✅ Sign up successful!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      //Chuyển hướng sang MainScreen và xóa trang Login
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $result'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // HÀM HIỂN THỊ HỘP THOẠI QUÊN MẬT KHẨU
  // ==========================================
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();

    if (_emailController.text.isNotEmpty) {
      resetEmailController.text = _emailController.text;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              String email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an email!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              String result = await _authService.resetPassword(email: email);

              if (!mounted) return;

              if (result.contains("Success")) {
                showDialog(
                  context: context,
                  builder: (BuildContext successContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Row(
                      children: [
                        Icon(
                          Icons.mark_email_read,
                          color: Colors.green,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Check your email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      'We have sent password recover instructions to your email.\n\n$email\n\nPlease check your inbox and spam folder.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(successContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C4B61),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext errorContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Oops! Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      result,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(errorContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C4B61),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Send Link',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN (UI) CHÍNH
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2C4B61);
    final Color lightBlue = const Color(0xFFE3F2FD);
    final Color accentBlue = const Color(0xFF8BB9D9);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 250,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentBlue.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentBlue.withValues(alpha: 0.6),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  Text(
                    isLogin ? 'Sign in' : 'Sign up',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLogin ? 'Welcome back' : 'Create an account here',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 60),

                  if (!isLogin)
                    _buildCustomTextField(
                      controller: _usernameController,
                      icon: Icons.person_outline,
                      hintText: 'Username',
                      accentBlue: accentBlue,
                    ),
                  if (!isLogin) const SizedBox(height: 30),

                  _buildCustomTextField(
                    controller: _emailController,
                    icon: Icons.mail_outline,
                    hintText: 'Email address',
                    accentBlue: accentBlue,
                  ),
                  const SizedBox(height: 30),

                  _buildCustomTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hintText: 'Password',
                    isPassword: true,
                    accentBlue: accentBlue,
                  ),
                  const SizedBox(height: 20),

                  if (isLogin)
                    Center(
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: primaryColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!isLogin)
                    Center(
                      child: Text(
                        'By signing up you agree with our Terms of Use',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                          _emailController.clear();
                          _passwordController.clear();
                          _usernameController.clear();
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: isLogin ? 'New member? ' : 'Already a member? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: isLogin ? 'Sign up' : 'Sign in',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    required Color accentBlue,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: accentBlue, width: 1.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 15),
          Container(height: 20, width: 1.5, color: accentBlue),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !isPasswordVisible,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
