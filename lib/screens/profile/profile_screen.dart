import '../settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/gamification_service.dart';
import 'edit_profile_screen.dart';
import 'library_screen.dart';
import '../../core/localization/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  //Tự động lấy chữ cái đầu của Tên hoặc Email làm Avatar
  String _getInitials(String? displayName, String? email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      List<String> names = displayName.trim().split(" ");
      if (names.length >= 2) {
        return (names[0][0] + names[names.length - 1][0]).toUpperCase();
      }
      return names[0][0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        final User? user = authSnapshot.data;

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null 
              ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
              : null,
          builder: (context, dbSnapshot) {
            final userData = dbSnapshot.data?.data() as Map<String, dynamic>?;
            final int totalXp = userData?['totalXp'] ?? 0;
            final int level = userData?['level'] ?? 1;
            final int streak = userData?['streak'] ?? 0;
            final int coins = userData?['coins'] ?? 0;

            final gamification = GamificationService();
            final int currentThreshold = gamification.getXpThreshold(level);
            final int nextThreshold = gamification.getXpThreshold(level + 1);
            final int progressXp = totalXp - currentThreshold;
            final int neededXp = nextThreshold - currentThreshold;

            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  _buildBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildProfileHeader(context, user, totalXp),
                                const SizedBox(height: 30),
                                
                                // Stats Cards
                                Row(
                                  children: [
                                    _buildStatCard(Icons.local_fire_department, "$streak", "Streak" , Colors.orange),
                                    const SizedBox(width: 8),
                                    _buildStatCard(Icons.diamond, "$coins", "Coins", Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    _buildStatCard(
                                      Icons.leaderboard,
                                      "Lv.$level", 
                                      "$progressXp/$neededXp", 
                                      Colors.green
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 40),

                                // Danh sách các nút Menu
                                _buildMenuTile(
                                  icon: Icons.library_books_outlined,
                                  title: AppStrings.of(context).library,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LibraryScreen()),
                                    );
                                  },
                                ),
                                _buildMenuTile(
                                  icon: Icons.person_outline,
                                  title: AppStrings.of(context).editProfile,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const EditProfileScreen()),
                                    );
                                  },
                                ),
                                _buildMenuTile(
                                  icon: Icons.settings_outlined,
                                  title: AppStrings.of(context).settings,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SettingsScreen()),
                                    );
                                  },
                                ),
                                _buildMenuTile(
                                  icon: Icons.info_outline,
                                  title: AppStrings.of(context).termsOfService,
                                  onTap: () {},
                                ),
                                _buildMenuTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: AppStrings.of(context).privacyPolicy,
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
          },
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN ---

  Widget _buildAppBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SizedBox(height: 40),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user, int totalXp) {
    // Xử lý dữ liệu fallback nếu người dùng chưa cập nhật tên/email
    final String displayName = user?.displayName ?? AppStrings.of(context).defaultUser;
    final String email = user?.email ?? AppStrings.of(context).noEmail;
    final String initials = _getInitials(user?.displayName, user?.email);

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
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name & Email & Total XP
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Total: $totalXp XP",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Nút mũi tên có PopupMenu Đăng xuất
        PopupMenuButton<String>(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          offset: const Offset(0, 40),

          color: Colors.white,
          elevation: 4,

          // Đẩy menu xuống để không che mất mũi tên
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              // Gọi lệnh đăng xuất của Firebase
              // StreamBuilder ở main.dart sẽ tự chuyển về AuthScreen
              await FirebaseAuth.instance.signOut();
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.blueGrey, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.of(context, listen: false).logOut,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
          ],
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
