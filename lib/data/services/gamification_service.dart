import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tính toán cấp độ dựa trên tổng XP (Cơ chế lũy tiến)
  // Tổng XP cho Level L = 500 * L * (L-1)
  int calculateLevel(int totalXp) {
    if (totalXp < 1000) return 1;
    // Giải phương trình bậc 2: 500L^2 - 500L - TotalXP = 0
    // Công thức nghiệm: L = (500 + sqrt(500^2 + 4*500*TotalXP)) / (2*500)
    // Rút gọn: L = (1 + sqrt(1 + TotalXP/125)) / 2
    double level = (1 + math.sqrt(1 + totalXp / 125)) / 2;
    return level.floor();
  }

  // Lấy ngưỡng XP của một cấp độ (Tổng XP cần để đạt cấp đó)
  int getXpThreshold(int level) {
    if (level <= 1) return 0;
    return 500 * level * (level - 1);
  }

  // Cập nhật XP, Level và Coins
  Future<void> addRewards(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      int currentXp = snapshot.data()?['totalXp'] ?? 0;
      int currentCoins = snapshot.data()?['coins'] ?? 0;
      
      int newXp = currentXp + amount;
      int newCoins = currentCoins + amount; // Thưởng coin tương đương XP
      int newLevel = calculateLevel(newXp);

      transaction.update(userRef, {
        'totalXp': newXp,
        'coins': newCoins,
        'level': newLevel,
        'lastStudyDate': FieldValue.serverTimestamp(),
      });
    });

    await updateStreak();
  }

  // Cập nhật Chuỗi ngày học (Streak)
  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final Timestamp? lastStudyTimestamp = data['lastStudyDate'];
    int currentStreak = data['streak'] ?? 0;

    if (lastStudyTimestamp == null) {
      await userRef.update({'streak': 1});
      return;
    }

    final DateTime lastStudyDate = lastStudyTimestamp.toDate();
    final DateTime now = DateTime.now();
    
    final lastDate = DateTime(lastStudyDate.year, lastStudyDate.month, lastStudyDate.day);
    final today = DateTime(now.year, now.month, now.day);
    
    final difference = today.difference(lastDate).inDays;

    if (difference == 1) {
      // Sang ngày mới, tăng streak
      await userRef.update({'streak': currentStreak + 1});
    } else if (difference > 1) {
      // Bị đứt chuỗi
      await userRef.update({'streak': 1});
    }
    // Nếu difference == 0 (cùng ngày), không làm gì cả
  }

  // Kiểm tra và trao Huy hiệu
  Future<void> checkBadges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final data = snapshot.data()!;
    
    List<String> currentBadges = List<String>.from(data['badges'] ?? []);
    int totalXp = data['totalXp'] ?? 0;
    int streak = data['streak'] ?? 0;

    bool updated = false;

    // Huy hiệu "Người mới"
    if (!currentBadges.contains('newbie') && totalXp > 0) {
      currentBadges.add('newbie');
      updated = true;
    }

    // Huy hiệu "Chiến binh 7 ngày"
    if (!currentBadges.contains('streak_7') && streak >= 7) {
      currentBadges.add('streak_7');
      updated = true;
    }

    if (updated) {
      await userRef.update({'badges': currentBadges});
    }
  }
}
