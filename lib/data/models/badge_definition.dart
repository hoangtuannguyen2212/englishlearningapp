import 'package:flutter/material.dart';

/// Định nghĩa một huy hiệu — metadata trong app, id lưu trên Firestore `users.badges`.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.titleEn,
    required this.titleVi,
    required this.conditionEn,
    required this.conditionVi,
    required this.icon,
    required this.isEarned,
  });

  final String id;
  final String titleEn;
  final String titleVi;
  final String conditionEn;
  final String conditionVi;
  final IconData icon;
  final bool Function(Map<String, dynamic> userData) isEarned;

  String title(bool isEnglish) => isEnglish ? titleEn : titleVi;

  String conditionHint(bool isEnglish) => isEnglish ? conditionEn : conditionVi;
}
