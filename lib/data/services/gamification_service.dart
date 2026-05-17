import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/badge_definition.dart';
import '../models/user_model.dart';
import 'badge_catalog.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static DateTime? _lastBadgeCheckAt;
  static const Duration _badgeCheckCooldown = Duration(seconds: 60);

  /// Khóa ngày theo giờ máy (yyyy-MM-dd) — tránh lệch UTC của server timestamp.
  static String dayKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Tính toán cấp độ dựa trên tổng XP (Cơ chế lũy tiến)
  // Tổng XP cho Level L = 500 * L * (L-1)
  int calculateLevel(int totalXp) {
    if (totalXp < 1000) return 1;
    double level = (1 + math.sqrt(1 + totalXp / 125)) / 2;
    return level.floor();
  }

  int getXpThreshold(int level) {
    if (level <= 1) return 0;
    return 500 * level * (level - 1);
  }

  static int _diamondFromData(Map<String, dynamic>? data) {
    if (data == null) return 0;
    return UserModel.diamondFromMap(data);
  }

  /// Gộp `coin` / `coins` cũ sang `diamond` (nếu thiếu) và xóa field legacy.
  Future<void> migrateLegacyCurrencyFields() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final bool hasCoin = data.containsKey('coin');
    final bool hasCoins = data.containsKey('coins');
    final bool hasDiamond = data.containsKey('diamond');

    if (!hasCoin && !hasCoins) return;

    final Map<String, dynamic> updates = {};
    if (!hasDiamond) {
      updates['diamond'] = _diamondFromData(data);
    }
    if (hasCoin) updates['coin'] = FieldValue.delete();
    if (hasCoins) updates['coins'] = FieldValue.delete();

    await userRef.update(updates);
  }

  Future<void> addRewards(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      int currentXp = snapshot.data()?['totalXp'] ?? 0;
      final data = snapshot.data()!;
      int currentDiamond = _diamondFromData(data);

      int newXp = currentXp + amount;
      int newDiamond = currentDiamond + amount;
      int newLevel = calculateLevel(newXp);

      final int quizzesCompleted =
          (data['quizzesCompleted'] as num?)?.toInt() ?? 0;

      final Map<String, dynamic> updates = {
        'totalXp': newXp,
        'diamond': newDiamond,
        'level': newLevel,
        'quizzesCompleted': quizzesCompleted + 1,
        'lastStudyDate': FieldValue.serverTimestamp(),
      };
      if (data.containsKey('coin')) {
        updates['coin'] = FieldValue.delete();
      }
      if (data.containsKey('coins')) {
        updates['coins'] = FieldValue.delete();
      }
      transaction.update(userRef, updates);
    });

    await updateStreak();
  }

  /// Ghi nhận ôn SRS (Easy/Hard) — tăng streak và thống kê.
  Future<void> recordSrsReview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.update({
      'srsReviewsCompleted': FieldValue.increment(1),
    });
    await updateStreak();
  }

  /// Ghi nhận hoàn thành bài học (một lần mỗi lesson id).
  Future<void> recordLessonCompleted(String lessonId) async {
    if (lessonId.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return;

    final completed =
        List<String>.from(snapshot.data()?['completedLessonIds'] ?? []);
    if (completed.contains(lessonId)) {
      await updateStreak();
      return;
    }

    completed.add(lessonId);
    await userRef.update({'completedLessonIds': completed});
    await updateStreak();
  }

  /// Cập nhật chuỗi ngày học — chỉ gọi sau hoạt động học (quiz / SRS / bài học).
  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    int currentStreak = data['streak'] ?? 0;

    final DateTime now = DateTime.now();
    final String todayKey = dayKey(now);
    final String yesterdayKey = dayKey(now.subtract(const Duration(days: 1)));

    String? lastStreakDay = data['lastStreakDay'] as String?;

    // Migrate từ lastStudyDate cũ (nếu chưa có lastStreakDay).
    if (lastStreakDay == null) {
      final Timestamp? lastStudyTimestamp = data['lastStudyDate'];
      if (lastStudyTimestamp != null) {
        lastStreakDay = dayKey(lastStudyTimestamp.toDate());
      }
    }

    if (lastStreakDay == todayKey) {
      // Đã ghi nhận hôm nay — không tăng thêm trong cùng ngày.
      if (currentStreak == 0) {
        await userRef.update({
          'streak': 1,
          'lastStreakDay': todayKey,
        });
      }
      return;
    }

    if (lastStreakDay == yesterdayKey) {
      await userRef.update({
        'streak': currentStreak + 1,
        'lastStreakDay': todayKey,
        'lastStudyDate': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Lần đầu hoặc đứt chuỗi (≥ 2 ngày).
    await userRef.update({
      'streak': 1,
      'lastStreakDay': todayKey,
      'lastStudyDate': FieldValue.serverTimestamp(),
    });
  }

  /// Kiểm tra điều kiện huy hiệu; trả về id badge **mới mở khóa** lần này.
  Future<List<String>> checkBadges({bool force = false}) async {
    if (!force &&
        _lastBadgeCheckAt != null &&
        DateTime.now().difference(_lastBadgeCheckAt!) < _badgeCheckCooldown) {
      return [];
    }

    final user = _auth.currentUser;
    if (user == null) return [];

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return [];

    final data = snapshot.data()!;
    final currentBadges = List<String>.from(data['badges'] ?? []);
    final newlyUnlocked = <String>[];

    for (final badge in BadgeCatalog.all) {
      if (currentBadges.contains(badge.id)) continue;
      final evalData = Map<String, dynamic>.from(data)
        ..['badges'] = List<String>.from(currentBadges);
      if (!badge.isEarned(evalData)) continue;
      currentBadges.add(badge.id);
      newlyUnlocked.add(badge.id);
    }

    if (newlyUnlocked.isNotEmpty) {
      await userRef.update({'badges': currentBadges});
    }

    _lastBadgeCheckAt = DateTime.now();
    return newlyUnlocked;
  }

  /// Lấy [BadgeDefinition] từ danh sách id đã mở khóa.
  List<BadgeDefinition> definitionsForIds(List<String> ids) {
    return ids
        .map(BadgeCatalog.byId)
        .whereType<BadgeDefinition>()
        .toList();
  }

  /// Id huy hiệu hiển thị trên Profile (đã lọc badge đã mở khóa).
  static List<String> displayBadgeIdsFrom(Map<String, dynamic> data) {
    final earned = Set<String>.from(data['badges'] ?? []);
    final List<String> raw;

    final idsField = data['displayBadgeIds'];
    if (idsField is List) {
      raw = idsField.whereType<String>().toList();
    } else {
      final legacy = data['displayBadgeId'];
      raw = legacy is String && legacy.isNotEmpty ? [legacy] : [];
    }

    final seen = <String>{};
    final result = <String>[];
    for (final id in raw) {
      if (!earned.contains(id) || seen.contains(id)) continue;
      seen.add(id);
      result.add(id);
    }
    return result;
  }

  /// Huy hiệu đang chọn hiển thị trên Profile (giữ thứ tự người dùng chọn).
  static List<BadgeDefinition> profileDisplayBadges(Map<String, dynamic> data) {
    return displayBadgeIdsFrom(data)
        .map(BadgeCatalog.byId)
        .whereType<BadgeDefinition>()
        .toList();
  }

  /// Bật/tắt một huy hiệu trên Profile.
  Future<bool> toggleProfileDisplayBadge(String badgeId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return false;

    final data = snapshot.data()!;
    final earned = List<String>.from(data['badges'] ?? []);
    if (!earned.contains(badgeId)) return false;

    final ids = List<String>.from(displayBadgeIdsFrom(data));
    if (ids.contains(badgeId)) {
      ids.remove(badgeId);
    } else {
      ids.add(badgeId);
    }

    await userRef.update({
      'displayBadgeIds': ids,
      'displayBadgeId': FieldValue.delete(),
    });
    return true;
  }

  /// Xóa toàn bộ huy hiệu trên Profile.
  Future<bool> clearProfileDisplayBadges() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await _firestore.collection('users').doc(user.uid).update({
      'displayBadgeIds': <String>[],
      'displayBadgeId': FieldValue.delete(),
    });
    return true;
  }
}
