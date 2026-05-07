import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Thêm gói Auth để kiểm tra trạng thái
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'main_screen.dart';

void main() async {
  // Đảm bảo Flutter đã sẵn sàng trước khi gọi Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình tự động nhận diện nền tảng
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vocabulary App',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A56F6), // Cập nhật màu xanh dương chủ đạo theo thiết kế
        useMaterial3: true,
      ),

      // ==========================================
      // TRẠM KIỂM SOÁT ĐĂNG NHẬP (AUTO-LOGIN LOGIC)
      // ==========================================
      home: StreamBuilder<User?>(
        // Lắng nghe liên tục xem người dùng đang Login hay Logout
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // Trạng thái 1: Đang chờ Firebase kiểm tra -> Hiện vòng xoay tải màu xanh
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A56F6)),
              ),
            );
          }

          // Trạng thái 2: ĐÃ ĐĂNG NHẬP (Có dữ liệu User) -> vào Màn hình chính
          if (snapshot.hasData) {
            return const MainScreen();
          }

          // Trạng thái 3: CHƯA ĐĂNG NHẬP (Hoặc vừa Đăng xuất) -> Hiện Màn hình Đăng nhập
          return const AuthScreen();
        },
      ),
    );
  }
}