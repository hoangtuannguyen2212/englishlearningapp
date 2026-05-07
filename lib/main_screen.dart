import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'ai_chatbot_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Biến lưu trữ vị trí tab đang được chọn (Mặc định là 0 - Home)
  int _selectedIndex = 0;

  // Danh sách các màn hình trống (sẽ thay thế bằng các file thật sau này)
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text('Khóa học (Courses) - Đang xây dựng', style: TextStyle(fontSize: 18))),
    const AIChatbotScreen(),
    const ProfileScreen(),
  ];

  // Hàm xử lý khi người dùng bấm vào các tab ở dưới
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF), // Màu nền xanh nhạt tổng thể của app

      // Phần thân: Hiển thị giao diện tương ứng với tab được chọn, giữ nguyên trạng thái
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // ================= Bottom Navigation Bar =================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5), // Tạo bóng đổ nhẹ lên trên
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined), // Icon hộp thoại chat
              activeIcon: Icon(Icons.forum),
              label: 'AI Chatbot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Me',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF2B3FD4),
          unselectedItemColor: const Color(0xFF6B7280), // Màu xám cho tab chưa chọn
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Đảm bảo luôn hiện chữ
          backgroundColor: Colors.white,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
    );
  }
}