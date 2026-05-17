import 'package:flutter/material.dart';

import '../models/badge_definition.dart';
import '../models/user_model.dart';

/// Danh sách huy hiệu tĩnh — thêm badge mới tại đây.
class BadgeCatalog {
  BadgeCatalog._();

  static final List<BadgeDefinition> all = [
    // —— Bắt đầu & XP ——
    BadgeDefinition(
      id: 'newbie',
      titleEn: 'First Steps',
      titleVi: 'Bước đầu tiên',
      conditionEn: 'Earn any XP',
      conditionVi: 'Nhận bất kỳ XP nào',
      icon: Icons.emoji_events_rounded,
      isEarned: _hasAnyXp,
    ),
    BadgeDefinition(
      id: 'xp_500',
      titleEn: 'Dedicated Student',
      titleVi: 'Học viên chăm chỉ',
      conditionEn: 'Reach 500 total XP',
      conditionVi: 'Đạt 500 XP tổng',
      icon: Icons.school_rounded,
      isEarned: _xpAtLeast(500),
    ),
    BadgeDefinition(
      id: 'xp_1000',
      titleEn: 'Knowledge Seeker',
      titleVi: 'Kẻ khao kiến tri thức',
      conditionEn: 'Reach 1,000 total XP',
      conditionVi: 'Đạt 1.000 XP tổng',
      icon: Icons.menu_book_rounded,
      isEarned: _xpAtLeast(1000),
    ),
    BadgeDefinition(
      id: 'xp_5000',
      titleEn: 'XP Champion',
      titleVi: 'Nhà vô địch XP',
      conditionEn: 'Reach 5,000 total XP',
      conditionVi: 'Đạt 5.000 XP tổng',
      icon: Icons.workspace_premium_rounded,
      isEarned: _xpAtLeast(5000),
    ),

    // —— Cấp độ ——
    BadgeDefinition(
      id: 'level_3',
      titleEn: 'Rising Learner',
      titleVi: 'Học viên đang lên',
      conditionEn: 'Reach level 3',
      conditionVi: 'Đạt cấp 3',
      icon: Icons.trending_up_rounded,
      isEarned: _levelAtLeast(3),
    ),
    BadgeDefinition(
      id: 'level_5',
      titleEn: 'Skilled Learner',
      titleVi: 'Học viên tài năng',
      conditionEn: 'Reach level 5',
      conditionVi: 'Đạt cấp 5',
      icon: Icons.insights_rounded,
      isEarned: _levelAtLeast(5),
    ),
    BadgeDefinition(
      id: 'level_10',
      titleEn: 'English Master',
      titleVi: 'Bậc thầy tiếng Anh',
      conditionEn: 'Reach level 10',
      conditionVi: 'Đạt cấp 10',
      icon: Icons.stars_rounded,
      isEarned: _levelAtLeast(10),
    ),

    // —— Kim cương ——
    BadgeDefinition(
      id: 'diamond_50',
      titleEn: 'Diamond Collector',
      titleVi: 'Nhà sưu tầm Kim cương',
      conditionEn: 'Collect 50 Diamonds',
      conditionVi: 'Thu thập 50 Kim cương',
      icon: Icons.diamond_rounded,
      isEarned: _diamondAtLeast(50),
    ),
    BadgeDefinition(
      id: 'diamond_100',
      titleEn: 'Gem Hoarder',
      titleVi: 'Kho kim cương',
      conditionEn: 'Collect 100 Diamonds',
      conditionVi: 'Thu thập 100 Kim cương',
      icon: Icons.diamond_outlined,
      isEarned: _diamondAtLeast(100),
    ),
    BadgeDefinition(
      id: 'diamond_200',
      titleEn: 'Treasure Keeper',
      titleVi: 'Thủ khố báu',
      conditionEn: 'Collect 200 Diamonds',
      conditionVi: 'Thu thập 200 Kim cương',
      icon: Icons.auto_awesome_rounded,
      isEarned: _diamondAtLeast(200),
    ),
    BadgeDefinition(
      id: 'diamond_500',
      titleEn: 'Diamond Tycoon',
      titleVi: 'Trùm kim cương',
      conditionEn: 'Collect 500 Diamonds',
      conditionVi: 'Thu thập 500 Kim cương',
      icon: Icons.volunteer_activism_rounded,
      isEarned: _diamondAtLeast(500),
    ),

    // —— Chuỗi ngày ——
    BadgeDefinition(
      id: 'streak_3',
      titleEn: 'On a Roll',
      titleVi: 'Giữ nhịp học',
      conditionEn: '3-day study streak',
      conditionVi: 'Chuỗi học 3 ngày',
      icon: Icons.whatshot_rounded,
      isEarned: _streakAtLeast(3),
    ),
    BadgeDefinition(
      id: 'streak_7',
      titleEn: 'Week Warrior',
      titleVi: 'Chiến binh 7 ngày',
      conditionEn: '7-day study streak',
      conditionVi: 'Chuỗi học 7 ngày',
      icon: Icons.local_fire_department_rounded,
      isEarned: _streakAtLeast(7),
    ),
    BadgeDefinition(
      id: 'streak_14',
      titleEn: 'Fortnight Focus',
      titleVi: 'Kiên trì 14 ngày',
      conditionEn: '14-day study streak',
      conditionVi: 'Chuỗi học 14 ngày',
      icon: Icons.bolt_rounded,
      isEarned: _streakAtLeast(14),
    ),
    BadgeDefinition(
      id: 'streak_30',
      titleEn: 'Monthly Legend',
      titleVi: 'Huyền thoại 30 ngày',
      conditionEn: '30-day study streak',
      conditionVi: 'Chuỗi học 30 ngày',
      icon: Icons.celebration_rounded,
      isEarned: _streakAtLeast(30),
    ),

    // —— Meta (đặt cuối) ——
    BadgeDefinition(
      id: 'badge_collector',
      titleEn: 'Badge Collector',
      titleVi: 'Nhà sưu tầm huy hiệu',
      conditionEn: 'Unlock 5 badges',
      conditionVi: 'Mở khóa 5 huy hiệu',
      icon: Icons.collections_rounded,
      isEarned: _badgeCountAtLeast(5),
    ),
    BadgeDefinition(
      id: 'badge_master',
      titleEn: 'Achievement Master',
      titleVi: 'Bậc thầy thành tựu',
      conditionEn: 'Unlock every other badge',
      conditionVi: 'Mở khóa tất cả huy hiệu còn lại',
      icon: Icons.military_tech_rounded,
      isEarned: _hasAllOtherBadges,
    ),
  ];

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
