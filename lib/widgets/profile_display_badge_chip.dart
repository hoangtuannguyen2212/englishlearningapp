import 'package:flutter/material.dart';

import '../data/models/badge_definition.dart';

/// Huy hiệu nhỏ hiển thị cạnh Total XP trên Profile.
class ProfileDisplayBadgeChip extends StatelessWidget {
  const ProfileDisplayBadgeChip({
    super.key,
    required this.badge,
    required this.isEnglish,
    this.compact = false,
  });

  final BadgeDefinition badge;
  final bool isEnglish;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = badge.title(isEnglish);

    return Tooltip(
      message: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF1A56F6)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A56F6).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge.icon, color: Colors.white, size: compact ? 14 : 16),
            if (!compact) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
