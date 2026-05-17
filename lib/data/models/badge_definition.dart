import 'package:flutter/material.dart';

enum BadgeCategory {
  starter,
  xp,
  level,
  study,
  streak,
  diamond,
  meta,
}

/// Định nghĩa một huy hiệu — metadata trong app, id lưu trên Firestore `users.badges`.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleVi,
    required this.conditionEn,
    required this.conditionVi,
    required this.icon,
    required this.isEarned,
  });

  final String id;
  final BadgeCategory category;
  final String titleEn;
  final String titleVi;
  final String conditionEn;
  final String conditionVi;
  final IconData icon;
  final bool Function(Map<String, dynamic> userData) isEarned;

  String title(bool isEnglish) => isEnglish ? titleEn : titleVi;

  String conditionHint(bool isEnglish) => isEnglish ? conditionEn : conditionVi;
}

/// Tiến độ hướng tới badge chưa mở (0.0–1.0).
class BadgeProgress {
  const BadgeProgress({
    required this.fraction,
    required this.labelEn,
    required this.labelVi,
  });

  final double fraction;
  final String labelEn;
  final String labelVi;

  String label(bool isEnglish) => isEnglish ? labelEn : labelVi;
}
