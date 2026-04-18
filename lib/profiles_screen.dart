import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Vẫn giữ Scaffold để có thể dùng nền hoặc các thuộc tính cơ bản
    // nhưng ĐÃ BỎ bottomNavigationBar
    return Scaffold(
      backgroundColor: Colors.white, // Đặt nền trắng mặc định
      body: Stack(
        children: [
          // Lớp 1: Background Gradient
          _buildBackground(),

          // Lớp 2: Nội dung chính
          SafeArea(
            child: Column(
              children: [
                // AppBar trong suốt
                _buildAppBar(),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Thông tin User (Avatar, Tên, Email)
                        _buildProfileHeader(),

                        const SizedBox(height: 40),

                        // Danh sách các nút Menu
                        _buildMenuTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () {},
                        ),
                        _buildMenuTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () {},
                        ),
                        _buildMenuTile(
                          icon: Icons.info_outline,
                          title: 'Terms of Service',
                          onTap: () {},
                        ),
                        _buildMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy policy',
                          onTap: () {},
                        ),
                      ],
                    ),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFF2962FF),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'Ma',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name & Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Mason',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'mason@gmail.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),

        const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.black54,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
}