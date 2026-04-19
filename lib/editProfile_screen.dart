import 'package:flutter/material.dart';

import 'auth_services.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

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
                      // Nút Change Username
                      _buildActionTile(
                        icon: Icons.person_outline,
                        title: 'Change Username',
                        onTap: () => _showChangeUsernameSheet(context),
                      ),

                      const SizedBox(height: 16),

                      // Nút Change Password
                      _buildActionTile(
                        icon: Icons.vpn_key_outlined, // Icon chìa khóa
                        title: 'Change Password',
                        onTap: () => _showChangePasswordSheet(context),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFF3F8FF),
            Colors.white,
          ],
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isLoading = false; // Biến quản lý trạng thái tải

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _BottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Change Username',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    hintText: 'New username',
                    controller: usernameController,
                  ),

                  const SizedBox(height: 24),
                  _buildSaveButton(
                      isLoading: isLoading, // Truyền trạng thái loading vào nút
                      onPressed: () async {
                        String newName = usernameController.text.trim();
                        if (newName.isEmpty) return;

                        // loading
                        setState(() { isLoading = true; });

                        //  Chờ Firebase xử lý
                        String result = await AuthService().updateUsername(newUsername: newName);

                        if (context.mounted) {
                          setState(() { isLoading = false; });
                          Navigator.pop(context); // Đóng bảng

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result == "Success" ? "Đổi tên thành công!" : result)),
                          );
                        }
                      }
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
            return _BottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    hintText: 'Current password',
                    controller: currentPassController,
                    isPassword: true,
                    obscureText: obscureCurrent,
                    onToggleVisibility: () => setState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    hintText: 'New password',
                    controller: newPassController,
                    isPassword: true,
                    obscureText: obscureNew,
                    onToggleVisibility: () => setState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    hintText: 'Confirm password',
                    controller: confirmPassController,
                    isPassword: true,
                    obscureText: obscureConfirm,
                    onToggleVisibility: () => setState(() => obscureConfirm = !obscureConfirm),
                  ),

                  const SizedBox(height: 24),

                  _buildSaveButton(
                      isLoading: isLoading, // Truyền trạng thái loading vào nút
                      onPressed: () async {
                        String currentPass = currentPassController.text;
                        String newPass = newPassController.text;
                        String confirmPass = confirmPassController.text;

                        if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin")));
                          return;
                        }
                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu mới không khớp!")));
                          return;
                        }

                        // 1. Bật vòng xoay loading
                        setState(() { isLoading = true; });

                        // 2. Chờ Firebase xử lý
                        String result = await AuthService().changePasswordWithReAuth(
                            currentPassword: currentPass,
                            newPassword: newPass
                        );

                        // 3. Tắt vòng xoay và hiển thị kết quả
                        if (context.mounted) {
                          setState(() { isLoading = false; });
                          if (result == "Success") {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công!")));
                          } else {
                            // Nếu lỗi (ví dụ sai pass cũ), không đóng bảng, chỉ báo lỗi để user sửa
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                          }
                        }
                      }
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

  // --- CÁC WIDGET DÙNG CHUNG CHO BOTTOM SHEET ---

  // Khung viền của Bottom Sheet (màu xanh nhạt nhạt, bo góc trên)
  Widget _BottomSheetContainer({required Widget child}) {
    return Builder(
        builder: (context) {
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
    );
  }

  // Thanh ngang nhỏ xíu trên cùng báo hiệu có thể vuốt
  Widget _buildSheetIndicator() {
    return Container(
      width: 60,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        // Bo góc và viền theo thiết kế
        enabledBorder: OutlineBorderCustom(),
        focusedBorder: OutlineBorderCustom(color: Colors.blueAccent, width: 1.5),
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
  OutlineInputBorder OutlineBorderCustom({Color color = Colors.black26, double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Nút Save xanh đậm
  Widget _buildSaveButton({required VoidCallback onPressed, bool isLoading = false}) {
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
            : const Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}