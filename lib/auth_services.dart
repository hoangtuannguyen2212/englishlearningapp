import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. HÀM ĐĂNG KÝ TÀI KHOẢN MỚI
  // ==========================================
  Future<String> registerUser({
    required String email,
    required String password,
    required String username
  }) async {
    try {
      // 1. Tạo tài khoản trên Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Cập nhật tên hiển thị (displayName) cho Firebase Auth ngay sau khi tạo
      await userCredential.user!.updateDisplayName(username);

      await userCredential.user!.reload();

      String uid = userCredential.user!.uid;

      // 2. Tạo hồ sơ lưu trữ thông tin chi tiết trên Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'email': email,
        'totalXp': 0,
        'streak': 0,
        'badges': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return "Successful";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password is too weak; it needs to be at least 6 characters long.';
      } else if (e.code == 'email-already-in-use') {
        return 'This email address has already been registered!';
      }
      return e.message ?? "Unknown Error";
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================
  // 2. HÀM ĐĂNG NHẬP
  // ==========================================
  Future<String> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Successful";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect email or password.';
      }
      return e.message ?? "Login error";
    }
  }

  // ==========================================
  // 3. HÀM ĐĂNG XUẤT
  // ==========================================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ==========================================
  // 4. HÀM QUÊN MẬT KHẨU (Đã thêm logic kiểm tra Database)
  // ==========================================
  Future<String> resetPassword({required String email}) async {
    try {
      // Tra cứu xem email có tồn tại trong bảng 'users' hay không
      var userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // Nếu không tìm thấy bất kỳ tài liệu nào khớp với email này
      if (userQuery.docs.isEmpty) {
        return "The account does not exist. Please double-check your email address!";
      }

      // Nếu tìm thấy, tiến hành gửi email khôi phục qua Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);
      return "Success: Please check your email inbox to reset your password.";

    } on FirebaseAuthException catch (e) {
      return "Error: Unable to send email. ${e.message}";
    } catch (e) {
      return "Connection error: ${e.toString()}";
    }
  }

  // ==========================================
  // 5. HÀM ĐỔI MẬT KHẨU TRỰC TIẾP (Dành cho sau này khi user đã vào trong app)
  // ==========================================
  Future<String> changePassword({required String newPassword}) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        return "Thành công: Đã đổi mật khẩu mới!";
      } else {
        return "Lỗi: Bạn chưa đăng nhập.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "Bảo mật: Bạn cần đăng xuất và đăng nhập lại trước khi đổi mật khẩu.";
      }
      return "Lỗi: ${e.message}";
    }
  }
}