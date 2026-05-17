import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../data/models/badge_definition.dart';
import '../providers/locale_provider.dart';

/// Dialog khi mở khóa một hoặc nhiều huy hiệu.
Future<void> showBadgeUnlockDialog(
  BuildContext context, {
  required List<BadgeDefinition> badges,
}) async {
  if (badges.isEmpty) return;

  final s = AppStrings.of(context, listen: false);
  final isEn = Provider.of<LocaleProvider>(context, listen: false).isEnglish;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  s.badgeUnlocked,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E384D),
                  ),
                ),
                const SizedBox(height: 16),
                ...badges.map(
                  (badge) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BadgeUnlockRow(
                      badge: badge,
                      isEnglish: isEn,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56F6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      s.ok,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BadgeUnlockRow extends StatelessWidget {
  const _BadgeUnlockRow({
    required this.badge,
    required this.isEnglish,
  });

  final BadgeDefinition badge;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1A56F6).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF1A56F6)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(badge.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              badge.title(isEnglish),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E384D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
