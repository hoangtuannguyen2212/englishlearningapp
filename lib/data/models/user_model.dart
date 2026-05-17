import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  /// Đọc [diamond]; tương thích field cũ `coin` / `coins`.
  static int diamondFromMap(Map<String, dynamic> map) {
    final dynamic diamond = map['diamond'];
    if (diamond is num) return diamond.toInt();
    final dynamic legacyCoin = map['coin'];
    if (legacyCoin is num) return legacyCoin.toInt();
    final dynamic legacyCoins = map['coins'];
    if (legacyCoins is num) return legacyCoins.toInt();
    return 0;
  }

  final String uid;
  final String username;
  final String email;
  final int totalXp;
  final int level;
  final int streak;
  final int diamond;
  final List<String> badges;
  final DateTime? lastStudyDate;
  final int dailyGoalXp;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.totalXp = 0,
    this.level = 1,
    this.streak = 0,
    this.diamond = 0,
    this.badges = const [],
    this.lastStudyDate,
    this.dailyGoalXp = 100,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      totalXp: map['totalXp'] ?? 0,
      level: map['level'] ?? 1,
      streak: map['streak'] ?? 0,
      diamond: UserModel.diamondFromMap(map),
      badges: List<String>.from(map['badges'] ?? []),
      lastStudyDate: map['lastStudyDate'] != null 
          ? (map['lastStudyDate'] as Timestamp).toDate() 
          : null,
      dailyGoalXp: map['dailyGoalXp'] ?? 100,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'totalXp': totalXp,
      'level': level,
      'streak': streak,
      'diamond': diamond,
      'badges': badges,
      'lastStudyDate': lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
      'dailyGoalXp': dailyGoalXp,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
