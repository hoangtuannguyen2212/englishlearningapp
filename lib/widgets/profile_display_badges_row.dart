import 'package:flutter/material.dart';

import '../data/models/badge_definition.dart';
import 'profile_display_badge_chip.dart';

/// Hàng huy hiệu cuộn ngang — dùng trên Profile và xem trước Thành tựu.
class ProfileDisplayBadgesRow extends StatelessWidget {
  const ProfileDisplayBadgesRow({
    super.key,
    required this.badges,
    required this.isEnglish,
    this.compact = true,
  });

  final List<BadgeDefinition> badges;
  final bool isEnglish;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < badges.length; i++) ...[
            if (i > 0) SizedBox(width: compact ? 6 : 8),
            ProfileDisplayBadgeChip(
              badge: badges[i],
              isEnglish: isEnglish,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}
