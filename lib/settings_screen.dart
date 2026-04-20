import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool _isNotificationOn = true;
  bool _isDarkModeOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Lớp nền Gradient xanh
          _buildBackground(),

          // 2. Nội dung chính
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Nút Language (Có chữ EN ở cuối)
                      _buildSettingTile(
                        icon: Icons.language,
                        title: 'Language',
                        trailing: const Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        onTap: () {
                          // Logic mở bảng chọn ngôn ngữ sau này
                        },
                      ),

                      const SizedBox(height: 16),

                      // Nút Notification (Có nút gạt)
                      _buildSettingTile(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notification',
                        // Dùng CupertinoSwitch
                        trailing: CupertinoSwitch(
                          value: _isNotificationOn,
                          activeColor: const Color(0xFF2962FF),
                          onChanged: (bool value) {
                            setState(() {
                              _isNotificationOn = value; // Cập nhật trạng thái
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nút Dark Mode
                      _buildSettingTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        trailing: CupertinoSwitch(
                          value: _isDarkModeOn,
                          activeColor: const Color(0xFF2962FF),
                          onChanged: (bool value) {
                            setState(() {
                              _isDarkModeOn = value; // Cập nhật trạng thái
                            });
                            // Logic đổi theme của app sẽ viết ở đây sau
                          },
                        ),
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

  // --- CÁC WIDGET THÀNH PHẦN ---

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context), // Bấm nút back để quay lại Profile
          ),
          const Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Hàm tạo từng thanh Setting linh hoạt
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing, // Widget nằm ở góc phải (có thể là Text hoặc Switch)
    VoidCallback? onTap,
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                // Hiển thị phần đuôi (Text "EN" hoặc Nút gạt Switch)
                trailing,
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
}