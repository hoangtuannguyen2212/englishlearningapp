import '../models/badge_definition.dart';
import '../models/user_model.dart';
import 'badge_catalog.dart';

class BadgeProgressHelper {
  BadgeProgressHelper._();

  static BadgeProgress? forBadge(
    BadgeDefinition badge,
    Map<String, dynamic> data,
  ) {
    if (badge.isEarned(data)) return null;

    switch (badge.id) {
      case 'newbie':
        return const BadgeProgress(
          fraction: 0,
          labelEn: 'Complete a quiz',
          labelVi: 'Hoàn thành một quiz',
        );
      case 'xp_500':
        return _ratio(_xp(data), 500, 'XP', 'XP');
      case 'xp_1000':
        return _ratio(_xp(data), 1000, 'XP', 'XP');
      case 'xp_5000':
        return _ratio(_xp(data), 5000, 'XP', 'XP');
      case 'level_3':
        return _ratio(_level(data), 3, 'Level', 'Cấp');
      case 'level_5':
        return _ratio(_level(data), 5, 'Level', 'Cấp');
      case 'level_10':
        return _ratio(_level(data), 10, 'Level', 'Cấp');
      case 'diamond_50':
        return _ratio(
          UserModel.diamondFromMap(data),
          50,
          'Diamonds',
          'Kim cương',
        );
      case 'streak_3':
        return _ratio(_streak(data), 3, 'days', 'ngày');
      case 'streak_7':
        return _ratio(_streak(data), 7, 'days', 'ngày');
      case 'streak_14':
        return _ratio(_streak(data), 14, 'days', 'ngày');
      case 'streak_30':
        return _ratio(_streak(data), 30, 'days', 'ngày');
      case 'quiz_5':
        return _ratio(_quizzes(data), 5, 'quizzes', 'quiz');
      case 'quiz_20':
        return _ratio(_quizzes(data), 20, 'quizzes', 'quiz');
      case 'srs_25':
        return _ratio(_srs(data), 25, 'SRS reviews', 'lần ôn SRS');
      case 'lesson_3':
        return _ratio(_lessons(data), 3, 'lessons', 'bài học');
      case 'badge_collector':
        final n = _badgeCount(data);
        return _ratio(n, 5, 'badges', 'huy hiệu');
      case 'badge_master':
        final total = BadgeCatalog.all.where((b) => b.id != 'badge_master').length;
        final earned = _badgeCount(data);
        return _ratio(earned, total, 'badges', 'huy hiệu');
      default:
        return null;
    }
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

  static BadgeProgress _ratio(
    int current,
    int target,
    String unitEn,
    String unitVi,
  ) {
    final safeTarget = target <= 0 ? 1 : target;
    final fraction = (current / safeTarget).clamp(0.0, 1.0);
    return BadgeProgress(
      fraction: fraction,
      labelEn: '$current / $target $unitEn',
      labelVi: '$current / $target $unitVi',
    );
  }
}
