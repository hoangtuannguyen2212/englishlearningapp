import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:englishlearningapp/data/services/auth_services.dart';
import 'package:englishlearningapp/core/localization/app_localizations.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Lớp nền (Background)
          _buildBackground(),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(context),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.person_outline,
                        title: AppStrings.of(context).changeUsername,
                        onTap: () => _showChangeUsernameSheet(context),
                      ),

                      const SizedBox(height: 16),

                      _buildActionTile(
                        icon: Icons.lock_reset,
                        title: AppStrings.of(context).forgotPassword,
                        onTap: () => _showForgotPasswordSheet(context),
                      ),

                      const SizedBox(height: 16),

                      _buildActionTile(
                        icon: Icons.vpn_key_outlined,
                        title: AppStrings.of(context).changePassword,
                        onTap: () => _showChangePasswordSheet(context),
                      ),

                      const SizedBox(height: 16),

                      _buildActionTile(
                        icon: Icons.delete_forever_outlined,
                        title: AppStrings.of(context).deleteAccount,
                        iconColor: Colors.redAccent,
                        titleColor: Colors.redAccent,
                        onTap: () => _showDeleteAccountSheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET GIAO DIỆN CHÍNH ---

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48), // Cân bằng với nút back
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final Color resolvedIconColor = iconColor ?? Colors.black87;
    final Color resolvedTitleColor = titleColor ?? Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Row(
              children: [
                Icon(icon, color: resolvedIconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: resolvedTitleColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFF3F8FF), Colors.white],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  // ==========================================
  // LOGIC BOTTOM SHEETS (BẢNG TRƯỢT LÊN)
  // ==========================================

  // 1. Bottom Sheet: Change Username
  void _showChangeUsernameSheet(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isLoading = false; // Biến quản lý trạng thái tải
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _bottomSheetContainer(
              context: context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).changeUsername,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    hintText: AppStrings.of(context).newUsername,
                    controller: usernameController,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    hintText: AppStrings.of(context).currentPassword,
                    controller: passwordController,
                    isPassword: true,
                    obscureText: obscurePassword,
                    onToggleVisibility: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(
                    context: context,
                    isLoading: isLoading, // Truyền trạng thái loading vào nút
                    onPressed: () async {
                      // 1. Thu hồi bàn phím ngay lập tức
                      FocusScope.of(context).unfocus();

                      String newName = usernameController.text.trim();
                      String currentPass = passwordController.text;
                      String? currentDisplayName =
                          FirebaseAuth.instance.currentUser?.displayName;

                      if (newName.isEmpty) {
                        _showErrorSnackBar(
                          context,
                          AppStrings.of(context).pleaseEnterUsername,
                        );
                        return;
                      }

                      // 2. Kiểm tra nếu tên mới trùng tên cũ
                      if (newName == currentDisplayName) {
                        _showErrorSnackBar(
                          context,
                          AppStrings.of(context).sameUsername,
                        );
                        return;
                      }

                      if (currentPass.isEmpty) {
                        _showErrorSnackBar(
                          context,
                          AppStrings.of(context).pleaseEnterPassword,
                        );
                        return;
                      }

                      // loading
                      setState(() {
                        isLoading = true;
                      });

                      //  Chờ Firebase xử lý
                      String result = await AuthService()
                          .updateUsernameWithReAuth(
                            currentPassword: currentPass,
                            newUsername: newName,
                          );

                      if (context.mounted) {
                        setState(() {
                          isLoading = false;
                        });
                        if (result == "Success") {
                          Navigator.pop(context); // Đóng bảng
                          _showSuccessSnackBar(
                            context,
                            AppStrings.of(context).usernameChanged,
                          );
                        } else {
                          // 3. Nếu sai mật khẩu hoặc có lỗi, xóa trắng ô mật khẩu để user nhập lại
                          passwordController.clear();
                          _showErrorSnackBar(context, result);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 1b. Bottom Sheet: Forgot Password
  void _showForgotPasswordSheet(BuildContext context) {
    final String? email = FirebaseAuth.instance.currentUser?.email;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _bottomSheetContainer(
              context: context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).forgotPassword,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).forgotPasswordDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    email ?? AppStrings.of(context).emailNotFound,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(
                    context: context,
                    isLoading: isLoading,
                    onPressed: () async {
                      if (email == null) {
                        _showErrorSnackBar(
                          context,
                          AppStrings.of(context).emailNotFound,
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      String result = await AuthService().resetPassword(
                        email: email,
                      );

                      if (context.mounted) {
                        setState(() => isLoading = false);
                        if (result.startsWith("Success")) {
                          Navigator.pop(context);
                          _showSuccessSnackBar(
                            context,
                            AppStrings.of(context).resetLinkSent,
                          );

                          // Chờ 2 giây để người dùng đọc thông báo rồi logout
                          Future.delayed(const Duration(seconds: 2), () {
                            FirebaseAuth.instance.signOut();
                          });
                        } else {
                          _showErrorSnackBar(context, result);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. Bottom Sheet: Change Password
  void _showChangePasswordSheet(BuildContext context) {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;
        bool isLoading = false; // Biến quản lý trạng thái tải

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _bottomSheetContainer(
              context: context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).changePassword,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    hintText: AppStrings.of(context).currentPassword,
                    controller: currentPassController,
                    isPassword: true,
                    obscureText: obscureCurrent,
                    onToggleVisibility: () =>
                        setState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    hintText: AppStrings.of(context).newPassword,
                    controller: newPassController,
                    isPassword: true,
                    obscureText: obscureNew,
                    onToggleVisibility: () =>
                        setState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    hintText: AppStrings.of(context).confirmPassword,
                    controller: confirmPassController,
                    isPassword: true,
                    obscureText: obscureConfirm,
                    onToggleVisibility: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(
                    context: context,
                    isLoading: isLoading, // Truyền trạng thái loading vào nút
                    onPressed: () async {
                      String currentPass = currentPassController.text;
                      String newPass = newPassController.text;
                      String confirmPass = confirmPassController.text;

                      if (currentPass.isEmpty ||
                          newPass.isEmpty ||
                          confirmPass.isEmpty) {
                        _showErrorSnackBar(
                          context,
                          AppStrings.of(context).pleaseFillAllFields,
                        );
                        return;
                      }
                      if (newPass != confirmPass) {
                        _showErrorSnackBar(
                          context,
                          AppStrings.of(context).passwordsDoNotMatch,
                        );
                        return;
                      }

                      // 1. Bật vòng xoay loading
                      setState(() {
                        isLoading = true;
                      });

                      // 2. Chờ Firebase xử lý
                      String result = await AuthService()
                          .changePasswordWithReAuth(
                            currentPassword: currentPass,
                            newPassword: newPass,
                          );

                      // 3. Tắt vòng xoay và hiển thị kết quả
                      if (context.mounted) {
                        setState(() {
                          isLoading = false;
                        });
                        if (result == "Success") {
                          Navigator.pop(context);
                          _showSuccessSnackBar(
                            context,
                            AppStrings.of(context).passwordChanged,
                          );

                          // Chờ 2 giây để người dùng đọc thông báo rồi logout
                          Future.delayed(const Duration(seconds: 2), () {
                            FirebaseAuth.instance.signOut();
                          });
                        } else {
                          // Nếu lỗi (ví dụ sai pass cũ), không đóng bảng, chỉ báo lỗi để user sửa
                          _showErrorSnackBar(context, result);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountSheet(BuildContext context) {
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool obscurePassword = true;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _bottomSheetContainer(
              context: context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context).deleteAccountConfirm,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.of(context).deleteAccountDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    hintText: AppStrings.of(context).typePasswordToConfirm,
                    controller: passwordController,
                    isPassword: true,
                    obscureText: obscurePassword,
                    onToggleVisibility: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final password = passwordController.text;
                              if (password.isEmpty) {
                                _showErrorSnackBar(
                                  context,
                                  AppStrings.of(context).pleaseEnterPassword,
                                );
                                return;
                              }

                              FocusScope.of(context).unfocus();
                              setState(() => isLoading = true);

                              final result = await AuthService().deleteAccount(
                                currentPassword: password,
                              );

                              if (!context.mounted) return;
                              setState(() => isLoading = false);

                              if (result == 'Successful') {
                                Navigator.pop(context);
                                _showSuccessSnackBar(
                                  context,
                                  AppStrings.of(context).accountDeleted,
                                );
                              } else {
                                _showErrorSnackBar(context, result);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              AppStrings.of(context).deleteAccountAction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(passwordController.dispose);
  }

  // --- CÁC WIDGET DÙNG CHUNG CHO BOTTOM SHEET ---

  // Khung viền của Bottom Sheet (màu xanh nhạt nhạt, bo góc trên)
  Widget _bottomSheetContainer({
    required BuildContext context,
    required Widget child,
  }) {
    // Lấy chiều cao bàn phím để đẩy sheet lên không bị che mất
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F8FF), // Màu nền xanh cực nhạt (AliceBlue)
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: child,
      ),
    );
  }

  // Thanh ngang nhỏ xíu trên cùng báo hiệu có thể vuốt
  Widget _buildSheetIndicator() {
    return Container(
      width: 60,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Ô nhập liệu (có thể có mắt nhắm mắt mở)
  Widget _buildTextField({
    required String hintText,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
        filled: true,
        fillColor: Colors.transparent, // Hoặc cho màu xám/xanh nhạt
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        // Bo góc và viền theo thiết kế
        enabledBorder: _outlineBorderCustom(),
        focusedBorder: _outlineBorderCustom(
          color: Colors.blueAccent,
          width: 1.5,
        ),
        // Nút con mắt cho mật khẩu
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black54,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }

  // Custom border cho gọn code
  OutlineInputBorder _outlineBorderCustom({
    Color color = Colors.black26,
    double width = 1.0,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Nút Save xanh đậm
  Widget _buildSaveButton({
    required BuildContext context,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // Nếu đang loading thì disable nút (gán null) để tránh user bấm nhiều lần
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF004481),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                AppStrings.of(context).save,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // --- HÀM HIỂN THỊ THÔNG BÁO (SỬ DỤNG OVERLAY ĐỂ KHÔNG BỊ MỜ) ---

  void _showErrorSnackBar(BuildContext context, String message) {
    _showTopNotification(context, message, true);
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    _showTopNotification(context, message, false);
  }

  void _showTopNotification(
    BuildContext context,
    String message,
    bool isError,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

// Widget thông báo nổi phía trên (Animation & Overlay)
class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5), // Bắt đầu từ ngoài màn hình phía trên
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Tự động đóng sau 3 giây
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isError ? Colors.redAccent : Colors.green,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.isError
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}