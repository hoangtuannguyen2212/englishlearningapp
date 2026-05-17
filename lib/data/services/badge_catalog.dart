import 'package:flutter/material.dart';

import '../models/badge_definition.dart';
import '../models/user_model.dart';

/// Danh sách huy hiệu tĩnh — thêm badge mới tại đây.
class BadgeCatalog {
  BadgeCatalog._();

  static final List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'newbie',
      category: BadgeCategory.starter,
      titleEn: 'First Steps',
      titleVi: 'Bước đầu tiên',
      conditionEn: 'Earn any XP from a quiz',
      conditionVi: 'Nhận XP từ quiz',
      icon: Icons.emoji_events_rounded,
      isEarned: _hasAnyXp,
    ),

    BadgeDefinition(
      id: 'xp_500',
      category: BadgeCategory.xp,
      titleEn: 'Dedicated Student',
      titleVi: 'Học viên chăm chỉ',
      conditionEn: 'Reach 500 total XP',
      conditionVi: 'Đạt 500 XP tổng',
      icon: Icons.school_rounded,
      isEarned: _xpAtLeast(500),
    ),
    BadgeDefinition(
      id: 'xp_1000',
      category: BadgeCategory.xp,
      titleEn: 'Knowledge Seeker',
      titleVi: 'Kẻ khao kiến tri thức',
      conditionEn: 'Reach 1,000 total XP',
      conditionVi: 'Đạt 1.000 XP tổng',
      icon: Icons.menu_book_rounded,
      isEarned: _xpAtLeast(1000),
    ),
    BadgeDefinition(
      id: 'xp_5000',
      category: BadgeCategory.xp,
      titleEn: 'XP Champion',
      titleVi: 'Nhà vô địch XP',
      conditionEn: 'Reach 5,000 total XP',
      conditionVi: 'Đạt 5.000 XP tổng',
      icon: Icons.workspace_premium_rounded,
      isEarned: _xpAtLeast(5000),
    ),

    BadgeDefinition(
      id: 'level_3',
      category: BadgeCategory.level,
      titleEn: 'Rising Learner',
      titleVi: 'Học viên đang lên',
      conditionEn: 'Reach level 3',
      conditionVi: 'Đạt cấp 3',
      icon: Icons.trending_up_rounded,
      isEarned: _levelAtLeast(3),
    ),
    BadgeDefinition(
      id: 'level_5',
      category: BadgeCategory.level,
      titleEn: 'Skilled Learner',
      titleVi: 'Học viên tài năng',
      conditionEn: 'Reach level 5',
      conditionVi: 'Đạt cấp 5',
      icon: Icons.insights_rounded,
      isEarned: _levelAtLeast(5),
    ),
    BadgeDefinition(
      id: 'level_10',
      category: BadgeCategory.level,
      titleEn: 'English Master',
      titleVi: 'Bậc thầy tiếng Anh',
      conditionEn: 'Reach level 10',
      conditionVi: 'Đạt cấp 10',
      icon: Icons.stars_rounded,
      isEarned: _levelAtLeast(10),
    ),

    BadgeDefinition(
      id: 'quiz_5',
      category: BadgeCategory.study,
      titleEn: 'Quiz Rookie',
      titleVi: 'Tân binh quiz',
      conditionEn: 'Complete 5 quizzes',
      conditionVi: 'Hoàn thành 5 quiz',
      icon: Icons.quiz_rounded,
      isEarned: _quizzesAtLeast(5),
    ),
    BadgeDefinition(
      id: 'quiz_20',
      category: BadgeCategory.study,
      titleEn: 'Quiz Veteran',
      titleVi: 'Cao thủ quiz',
      conditionEn: 'Complete 20 quizzes',
      conditionVi: 'Hoàn thành 20 quiz',
      icon: Icons.fact_check_rounded,
      isEarned: _quizzesAtLeast(20),
    ),
    BadgeDefinition(
      id: 'srs_25',
      category: BadgeCategory.study,
      titleEn: 'Memory Builder',
      titleVi: 'Rèn trí nhớ',
      conditionEn: 'Complete 25 SRS reviews',
      conditionVi: 'Ôn SRS 25 lần',
      icon: Icons.psychology_rounded,
      isEarned: _srsAtLeast(25),
    ),
    BadgeDefinition(
      id: 'lesson_3',
      category: BadgeCategory.study,
      titleEn: 'Course Explorer',
      titleVi: 'Khám phá khóa học',
      conditionEn: 'Finish 3 lessons',
      conditionVi: 'Hoàn thành 3 bài học',
      icon: Icons.explore_rounded,
      isEarned: _lessonsAtLeast(3),
    ),

    BadgeDefinition(
      id: 'diamond_50',
      category: BadgeCategory.diamond,
      titleEn: 'Diamond Collector',
      titleVi: 'Nhà sưu tầm Kim cương',
      conditionEn: 'Collect 50 Diamonds',
      conditionVi: 'Thu thập 50 Kim cương',
      icon: Icons.diamond_rounded,
      isEarned: _diamondAtLeast(50),
    ),

    BadgeDefinition(
      id: 'streak_3',
      category: BadgeCategory.streak,
      titleEn: 'On a Roll',
      titleVi: 'Giữ nhịp học',
      conditionEn: '3-day study streak',
      conditionVi: 'Chuỗi học 3 ngày',
      icon: Icons.whatshot_rounded,
      isEarned: _streakAtLeast(3),
    ),
    BadgeDefinition(
      id: 'streak_7',
      category: BadgeCategory.streak,
      titleEn: 'Week Warrior',
      titleVi: 'Chiến binh 7 ngày',
      conditionEn: '7-day study streak',
      conditionVi: 'Chuỗi học 7 ngày',
      icon: Icons.local_fire_department_rounded,
      isEarned: _streakAtLeast(7),
    ),
    BadgeDefinition(
      id: 'streak_14',
      category: BadgeCategory.streak,
      titleEn: 'Fortnight Focus',
      titleVi: 'Kiên trì 14 ngày',
      conditionEn: '14-day study streak',
      conditionVi: 'Chuỗi học 14 ngày',
      icon: Icons.bolt_rounded,
      isEarned: _streakAtLeast(14),
    ),
    BadgeDefinition(
      id: 'streak_30',
      category: BadgeCategory.streak,
      titleEn: 'Monthly Legend',
      titleVi: 'Huyền thoại 30 ngày',
      conditionEn: '30-day study streak',
      conditionVi: 'Chuỗi học 30 ngày',
      icon: Icons.celebration_rounded,
      isEarned: _streakAtLeast(30),
    ),

    BadgeDefinition(
      id: 'badge_collector',
      category: BadgeCategory.meta,
      titleEn: 'Badge Collector',
      titleVi: 'Nhà sưu tầm huy hiệu',
      conditionEn: 'Unlock 5 badges',
      conditionVi: 'Mở khóa 5 huy hiệu',
      icon: Icons.collections_rounded,
      isEarned: _badgeCountAtLeast(5),
    ),
    BadgeDefinition(
      id: 'badge_master',
      category: BadgeCategory.meta,
      titleEn: 'Achievement Master',
      titleVi: 'Bậc thầy thành tựu',
      conditionEn: 'Unlock every other badge',
      conditionVi: 'Mở khóa tất cả huy hiệu còn lại',
      icon: Icons.military_tech_rounded,
      isEarned: _hasAllOtherBadges,
    ),
  ];

  static const List<BadgeCategory> displayCategories = [
    BadgeCategory.starter,
    BadgeCategory.study,
    BadgeCategory.xp,
    BadgeCategory.level,
    BadgeCategory.streak,
    BadgeCategory.diamond,
    BadgeCategory.meta,
  ];

  static List<BadgeDefinition> byCategory(BadgeCategory category) {
    return all.where((b) => b.category == category).toList();
  }

  static BadgeDefinition? byId(String id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }

  static int _xp(Map<String, dynamic> data) =>
      (data['totalXp'] as num?)?.toInt() ?? 0;

  static int _level(Map<String, dynamic> data) =>
      (data['level'] as num?)?.toInt() ?? 1;

  static int _streak(Map<String, dynamic> data) =>
      (data['streak'] as num?)?.toInt() ?? 0;

  static int _quizzes(Map<String, dynamic> data) =>
      (data['quizzesCompleted'] as num?)?.toInt() ?? 0;

  static int _srs(Map<String, dynamic> data) =>
      (data['srsReviewsCompleted'] as num?)?.toInt() ?? 0;

  static int _lessons(Map<String, dynamic> data) =>
      List<String>.from(data['completedLessonIds'] ?? []).length;

  static int _badgeCount(Map<String, dynamic> data) =>
      List<String>.from(data['badges'] ?? []).length;

  static bool _hasAnyXp(Map<String, dynamic> data) => _xp(data) > 0;

  static bool Function(Map<String, dynamic>) _xpAtLeast(int min) =>
      (data) => _xp(data) >= min;

  static bool Function(Map<String, dynamic>) _levelAtLeast(int min) =>
      (data) => _level(data) >= min;

  static bool Function(Map<String, dynamic>) _diamondAtLeast(int min) =>
      (data) => UserModel.diamondFromMap(data) >= min;

  static bool Function(Map<String, dynamic>) _streakAtLeast(int min) =>
      (data) => _streak(data) >= min;

  static bool Function(Map<String, dynamic>) _quizzesAtLeast(int min) =>
      (data) => _quizzes(data) >= min;

  static bool Function(Map<String, dynamic>) _srsAtLeast(int min) =>
      (data) => _srs(data) >= min;

  static bool Function(Map<String, dynamic>) _lessonsAtLeast(int min) =>
      (data) => _lessons(data) >= min;

  static bool Function(Map<String, dynamic>) _badgeCountAtLeast(int min) =>
      (data) => _badgeCount(data) >= min;

  static bool _hasAllOtherBadges(Map<String, dynamic> data) {
    final earned = Set<String>.from(data['badges'] ?? []);
    for (final badge in all) {
      if (badge.id == 'badge_master') continue;
      if (!earned.contains(badge.id)) return false;
    }
    return true;
  }
}
