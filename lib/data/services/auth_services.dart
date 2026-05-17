import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'remember_account_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _hasFirestoreProfileForEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> _hasFirestoreProfileForUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String username,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'username': username,
      'email': email.trim(),
      'totalXp': 0,
      'level': 1,
      'streak': 0,
      'diamond': 0,
      'badges': [],
      'displayBadgeIds': <String>[],
      'quizzesCompleted': 0,
      'srsReviewsCompleted': 0,
      'completedLessonIds': <String>[],
      'lastStudyDate': null,
      'lastStreakDay': null,
      'dailyGoalXp': 100,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Auth còn nhưng document Firestore đã bị xóa — đăng nhập và tạo lại hồ sơ.
  Future<String> _recoverOrphanedAuthAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = _auth.currentUser;
      if (user == null) {
        return 'Could not restore account. Please try again.';
      }

      await user.updateDisplayName(username.trim());
      await user.reload();

      if (!await _hasFirestoreProfileForUid(user.uid)) {
        await _createUserProfile(
          uid: user.uid,
          email: email,
          username: username,
        );
      }

      return 'Successful';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return 'This email is already registered in Authentication. '
            'Sign in with your old password, use Forgot Password, '
            'or delete the user in Firebase Console → Authentication.';
      }
      return e.message ?? 'Could not restore account.';
    }
  }

  Future<void> _ensureFirestoreProfileAfterLogin({
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (await _hasFirestoreProfileForUid(user.uid)) return;

    final displayName = user.displayName?.trim();
    await _createUserProfile(
      uid: user.uid,
      email: email,
      username: displayName != null && displayName.isNotEmpty
          ? displayName
          : email.split('@').first,
    );
  }

  // ==========================================
  // 1. HÀM ĐĂNG KÝ TÀI KHOẢN MỚI
  // ==========================================
  Future<String> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    final trimmedEmail = email.trim();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      await userCredential.user!.updateDisplayName(username.trim());
      await userCredential.user!.reload();

      final uid = userCredential.user!.uid;
      await _createUserProfile(
        uid: uid,
        email: trimmedEmail,
        username: username,
      );

      return 'Successful';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password is too weak; it needs to be at least 6 characters long.';
      }
      if (e.code == 'email-already-in-use') {
        final hasProfile = await _hasFirestoreProfileForEmail(trimmedEmail);
        if (hasProfile) {
          return 'This email address has already been registered! Use Sign in.';
        }
        return _recoverOrphanedAuthAccount(
          email: trimmedEmail,
          password: password,
          username: username,
        );
      }
      return e.message ?? 'Unknown Error';
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================
  // 2. HÀM ĐĂNG NHẬP
  // ==========================================
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    try {
      await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      await _ensureFirestoreProfileAfterLogin(email: trimmedEmail);
      return 'Successful';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return 'Incorrect email or password.';
      }
      return e.message ?? 'Login error';
    }
  }

  Future<void> _deleteAllUserProgress(String uid) async {
    final progressRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('user_progress');

    while (true) {
      final snapshot = await progressRef.limit(500).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Xóa hoàn toàn: user_progress + document users + Firebase Authentication.
  Future<String> deleteAccount({required String currentPassword}) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return 'Error: You are not logged in.';
      }

      final String email = user.email!;
      final String uid = user.uid;

      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await _deleteAllUserProgress(uid);
      await _firestore.collection('users').doc(uid).delete();

      await NotificationService().stopFirestoreSync();
      await NotificationService().cancelAllReminders();
      await RememberAccountService().remove(email);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history_$uid');

      await user.delete();

      return 'Successful';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return 'Incorrect password. Account was not deleted.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Please sign out, sign in again, then retry deleting your account.';
      }
      return e.message ?? 'Could not delete account.';
    } catch (e) {
      return 'Could not delete account: ${e.toString()}';
    }
  }

  // ==========================================
  // 3. HÀM ĐĂNG XUẤT
  // ==========================================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ==========================================
  // 4. HÀM QUÊN MẬT KHẨU
  // ==========================================
  Future<String> resetPassword({required String email}) async {
    final trimmedEmail = email.trim();

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: trimmedEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await _auth.sendPasswordResetEmail(email: trimmedEmail);
        return 'Success: Please check your email inbox to reset your password.';
      }

      // Không có document Firestore — vẫn thử Auth (trường hợp xóa document thủ công).
      try {
        await _auth.sendPasswordResetEmail(email: trimmedEmail);
        return 'Success: Please check your email inbox to reset your password.';
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          return 'The account does not exist. Please double-check your email address!';
        }
        return 'Error: Unable to send email. ${e.message}';
      }
    } on FirebaseAuthException catch (e) {
      return 'Error: Unable to send email. ${e.message}';
    } catch (e) {
      return 'Connection error: ${e.toString()}';
    }
  }

  // ==========================================
  // 5. HÀM ĐỔI MẬT KHẨU TRỰC TIẾP (Không xác thực lại)
  // ==========================================
  Future<String> changePassword({required String newPassword}) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        return 'Thành công: Đã đổi mật khẩu mới!';
      } else {
        return 'Lỗi: Bạn chưa đăng nhập.';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Bảo mật: Bạn cần đăng xuất và đăng nhập lại trước khi đổi mật khẩu.';
      }
      return 'Lỗi: ${e.message}';
    }
  }

  // ==========================================
  // 6. ĐỔI TÊN NGƯỜI DÙNG (Cập nhật cả 2 kho)
  // ==========================================
  Future<String> updateUsername({required String newUsername}) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newUsername);
        await user.reload();

        await _firestore.collection('users').doc(user.uid).update({
          'username': newUsername,
        });
        return 'Success';
      }
      return 'Lỗi: Không tìm thấy tài khoản.';
    } catch (e) {
      return 'Lỗi cập nhật tên: ${e.toString()}';
    }
  }

  // ==========================================
  // 6b. ĐỔI TÊN NGƯỜI DÙNG CÓ XÁC THỰC LẠI
  // ==========================================
  Future<String> updateUsernameWithReAuth({
    required String currentPassword,
    required String newUsername,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        await user.updateDisplayName(newUsername);
        await user.reload();

        await _firestore.collection('users').doc(user.uid).update({
          'username': newUsername,
        });
        return 'Success';
      }
      return 'Lỗi: Phiên đăng nhập không hợp lệ.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.message?.contains('auth credential is incorrect') == true) {
        return 'Mật khẩu hiện tại không chính xác!';
      }
      return e.message ?? 'Lỗi xác thực';
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================
  // 7. ĐỔI MẬT KHẨU CÓ XÁC THỰC LẠI (Dùng cho Edit Profile Screen)
  // ==========================================
  Future<String> changePasswordWithReAuth({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user != null && user.email != null) {
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        return 'Success';
      }
      return 'Lỗi: Phiên đăng nhập không hợp lệ.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.message?.contains('auth credential is incorrect') == true) {
        return 'Mật khẩu hiện tại không chính xác!';
      }
      return e.message ?? 'Lỗi không xác định';
    } catch (e) {
      return e.toString();
    }
  }
}
