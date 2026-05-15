import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:englishlearningapp/data/services/auth_services.dart';
import 'package:englishlearningapp/data/services/remember_account_service.dart';
import 'package:englishlearningapp/core/localization/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool _rememberAccount = false;
  List<RememberedAccount> _savedAccounts = [];

  final RememberAccountService _rememberAccountService = RememberAccountService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadSavedAccounts(fillMostRecent: true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _reloadSavedAccounts({bool fillMostRecent = false}) async {
    if (!isLogin) return;

    final accounts = await _rememberAccountService.loadAll();
    if (!mounted) return;

    setState(() => _savedAccounts = accounts);

    if (fillMostRecent && accounts.isNotEmpty && _emailController.text.isEmpty) {
      _applySavedAccount(accounts.first, markRemember: true);
    }
  }

  void _applySavedAccount(RememberedAccount account, {bool markRemember = true}) {
    _emailController.value = TextEditingValue(
      text: account.email,
      selection: TextSelection.collapsed(offset: account.email.length),
    );
    if (markRemember) {
      setState(() => _rememberAccount = true);
    }
  }

  Future<void> _removeSavedAccount(RememberedAccount account) async {
    await _rememberAccountService.remove(account.email);
    if (!mounted) return;

    final isCurrent = _emailController.text.trim().toLowerCase() ==
        account.email.trim().toLowerCase();
    if (isCurrent) {
      _emailController.clear();
    }

    await _reloadSavedAccounts();
    if (!mounted) return;

    if (_savedAccounts.isEmpty) {
      setState(() => _rememberAccount = false);
    }
  }

  /// Lưu tài khoản — gọi ngay sau login thành công, không phụ thuộc widget còn mounted.
  Future<void> _persistRememberAccount({
    required bool remember,
    required String email,
    required String password,
  }) async {
    if (!remember || email.trim().isEmpty) return;

    await _rememberAccountService.save(
      email: email.trim(),
      displayName: FirebaseAuth.instance.currentUser?.displayName,
      password: password,
    );
  }

  // ==========================================
  // HÀM XỬ LÝ ĐĂNG NHẬP / ĐĂNG KÝ
  // ==========================================
  void _submitAuth() async {
    FocusScope.of(context).unfocus();

    // Chụp trạng thái trước khi await — sau login MainScreen thay AuthScreen ngay.
    final bool shouldRemember = isLogin && _rememberAccount;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() => isLoading = true);

    String result;
    if (isLogin) {
      result = await _authService.loginUser(
        email: email,
        password: password,
      );
    } else {
      result = await _authService.registerUser(
        email: email,
        password: password,
        username: _usernameController.text.trim(),
      );
    }

    if (result == "Successful") {
      // Lưu TRƯỚC setState — tránh dispose AuthScreen làm gián đoạn luồng lưu.
      if (shouldRemember) {
        await _persistRememberAccount(
          remember: true,
          email: email,
          password: password,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLogin ? '✅ Sign in successful!' : '✅ Sign up successful!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      // StreamBuilder trong main.dart tự chuyển sang MainScreen khi đã đăng nhập.
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $result'), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
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
                  if (isLogin && _savedAccounts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSavedAccountsRow(context, primaryColor),
                  ],
                  const SizedBox(height: 30),

                  _buildCustomTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hintText: 'Password',
                    isPassword: true,
                    accentBlue: accentBlue,
                  ),
                  const SizedBox(height: 16),

                  if (isLogin)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _rememberAccount = !_rememberAccount),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberAccount,
                              onChanged: (value) => setState(
                                () => _rememberAccount = value ?? false,
                              ),
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.of(context).rememberAccountOnLogin,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isLogin) const SizedBox(height: 12),

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
                      onTap: () async {
                        final switchingToLogin = !isLogin;
                        setState(() {
                          isLogin = switchingToLogin;
                          _passwordController.clear();
                          _usernameController.clear();
                          if (!switchingToLogin) {
                            _emailController.clear();
                            _rememberAccount = false;
                          }
                        });
                        if (switchingToLogin) {
                          await _reloadSavedAccounts(fillMostRecent: true);
                        }
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

  Widget _buildSavedAccountsRow(BuildContext context, Color primaryColor) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.savedAccountsCount(_savedAccounts.length),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _savedAccounts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final account = _savedAccounts[index];
              final isSelected = _emailController.text.trim().toLowerCase() ==
                  account.email.trim().toLowerCase();

              return InputChip(
                avatar: CircleAvatar(
                  backgroundColor:
                      isSelected ? primaryColor : Colors.grey.shade300,
                  child: Text(
                    account.initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                label: Text(
                  account.shortLabel,
                  style: const TextStyle(fontSize: 13),
                ),
                selected: isSelected,
                selectedColor: primaryColor.withValues(alpha: 0.15),
                showCheckmark: false,
                onPressed: () => _applySavedAccount(account),
                onDeleted: () => _removeSavedAccount(account),
                deleteIconColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
      ],
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