import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/badge_definition.dart';
import '../../data/services/badge_catalog.dart';
import '../../data/services/badge_progress.dart';
import '../../data/services/gamification_service.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/profile_display_badges_row.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEn = Provider.of<LocaleProvider>(context).isEnglish;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: Text(
          s.achievements,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1A56F6),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? Center(child: Text(s.notLoggedIn))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final earned = List<String>.from(data['badges'] ?? []);
                final displayBadgeIds =
                    GamificationService.displayBadgeIdsFrom(data);
                final total = BadgeCatalog.all.length;
                final unlocked = earned.length;
                final displayBadges =
                    GamificationService.profileDisplayBadges(data);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _ProfileBadgeSection(
                          earned: earned,
                          displayBadgeIds: displayBadgeIds,
                          displayBadges: displayBadges,
                          isEnglish: isEn,
                          totalXp: data['totalXp'] as int? ?? 0,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.badgesProgress(unlocked, total),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E384D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.achievementsSubtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.55),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: total > 0 ? unlocked / total : 0,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF1A56F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ..._badgeCategorySlivers(
                      context: context,
                      s: s,
                      userData: data,
                      earned: earned,
                      displayBadgeIds: displayBadgeIds,
                      isEnglish: isEn,
                    ),
                  ],
                );
              },
            ),
    );
  }

  static Future<void> _toggleDisplayBadge(
    BuildContext context,
    String badgeId,
  ) async {
    await GamificationService().toggleProfileDisplayBadge(badgeId);
  }

  static List<Widget> _badgeCategorySlivers({
    required BuildContext context,
    required AppStrings s,
    required Map<String, dynamic> userData,
    required List<String> earned,
    required List<String> displayBadgeIds,
    required bool isEnglish,
  }) {
    final slivers = <Widget>[];

    for (final category in BadgeCatalog.displayCategories) {
      final badges = BadgeCatalog.byCategory(category);
      if (badges.isEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              s.badgeCategoryTitle(category),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E384D),
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final badge = badges[index];
                final isUnlocked = earned.contains(badge.id);
                final isFeatured =
                    displayBadgeIds.contains(badge.id) && isUnlocked;
                return _BadgeCard(
                  badge: badge,
                  userData: userData,
                  isUnlocked: isUnlocked,
                  isFeatured: isFeatured,
                  isEnglish: isEnglish,
                  lockedLabel: s.badgeLocked,
                  unlockedLabel: s.badgeUnlockedStatus,
                  featuredLabel: s.displayOnProfile,
                  onTap: isUnlocked
                      ? () => _toggleDisplayBadge(context, badge.id)
                      : null,
                );
              },
              childCount: badges.length,
            ),
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return slivers;
  }
}

class _ProfileBadgeSection extends StatefulWidget {
  const _ProfileBadgeSection({
    required this.earned,
    required this.displayBadgeIds,
    required this.displayBadges,
    required this.isEnglish,
    required this.totalXp,
  });

  final List<String> earned;
  final List<String> displayBadgeIds;
  final List<BadgeDefinition> displayBadges;
  final bool isEnglish;
  final int totalXp;

  @override
  State<_ProfileBadgeSection> createState() => _ProfileBadgeSectionState();
}

class _ProfileBadgeSectionState extends State<_ProfileBadgeSection> {
  String? _busyBadgeId;
  bool _clearingAll = false;

  List<BadgeDefinition> get _unlockedBadges => widget.earned
      .map(BadgeCatalog.byId)
      .whereType<BadgeDefinition>()
      .toList();

  Future<void> _toggle(String badgeId) async {
    if (_busyBadgeId != null || _clearingAll) return;
    setState(() => _busyBadgeId = badgeId);

    await GamificationService().toggleProfileDisplayBadge(badgeId);

    if (!mounted) return;
    setState(() => _busyBadgeId = null);
  }

  Future<void> _clearAll() async {
    if (_busyBadgeId != null || _clearingAll) return;
    setState(() => _clearingAll = true);

    await GamificationService().clearProfileDisplayBadges();

    if (!mounted) return;
    setState(() => _clearingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? s.defaultUser;
    final initials = displayName.isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    final previewBadges = widget.displayBadges;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A56F6), Color(0xFF7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56F6).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Icon(
                Icons.military_tech_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.profileBadge,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.profileBadgeSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.profileBadgePreview,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF2962FF),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Total: ${widget.totalXp} XP',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      if (previewBadges.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: ProfileDisplayBadgesRow(
                                            badges: previewBadges,
                                            isEnglish: widget.isEnglish,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (previewBadges.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      s.profileBadgesOnProfile(
                                        previewBadges.length,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_unlockedBadges.isEmpty)
                    Text(
                      s.profileBadgeTapToSelect,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                  else ...[
                    Text(
                      s.profileBadgeTapToSelect,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _BadgePickerTile(
                            label: s.profileBadgeClearAll,
                            icon: Icons.clear_all_rounded,
                            isSelected: widget.displayBadgeIds.isEmpty,
                            isLoading: _clearingAll,
                            onTap: (_busyBadgeId != null || _clearingAll)
                                ? null
                                : _clearAll,
                          ),
                          ..._unlockedBadges.map((badge) {
                            final selected =
                                widget.displayBadgeIds.contains(badge.id);
                            return _BadgePickerTile(
                              label: badge.title(widget.isEnglish),
                              icon: badge.icon,
                              isSelected: selected,
                              isLoading: _busyBadgeId == badge.id,
                              onTap: (_busyBadgeId != null || _clearingAll)
                                  ? null
                                  : () => _toggle(badge.id),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePickerTile extends StatelessWidget {
  const _BadgePickerTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isLoading,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isSelected
                          ? const Color(0xFF1A56F6)
                          : Colors.white,
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? const Color(0xFF1A56F6)
                        : Colors.white,
                  ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF2E384D)
                        : Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.userData,
    required this.isUnlocked,
    required this.isFeatured,
    required this.isEnglish,
    required this.lockedLabel,
    required this.unlockedLabel,
    required this.featuredLabel,
    this.onTap,
  });

  final BadgeDefinition badge;
  final Map<String, dynamic> userData;
  final bool isUnlocked;
  final bool isFeatured;
  final bool isEnglish;
  final String lockedLabel;
  final String unlockedLabel;
  final String featuredLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final definition = badge;
    final progress = BadgeProgressHelper.forBadge(badge, userData);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFeatured
                  ? const Color(0xFF7C4DFF)
                  : isUnlocked
                      ? const Color(0xFF1A56F6).withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.06),
              width: isFeatured ? 2 : isUnlocked ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isFeatured
                    ? const Color(0xFF7C4DFF).withValues(alpha: 0.2)
                    : isUnlocked
                        ? const Color(0xFF1A56F6).withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isUnlocked
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF7C4DFF), Color(0xFF1A56F6)],
                            )
                          : null,
                      color: isUnlocked ? null : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      definition.icon,
                      color: isUnlocked ? Colors.white : Colors.grey.shade500,
                      size: 26,
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (isFeatured)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF1A56F6)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              featuredLabel,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                definition.title(isEnglish),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked
                      ? const Color(0xFF2E384D)
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUnlocked
                    ? unlockedLabel
                    : definition.conditionHint(isEnglish),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: isUnlocked
                      ? Colors.green.shade600
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ),
              if (!isUnlocked && progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 5,
                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF1A56F6),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.label(isEnglish),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
              if (!isUnlocked) ...[
                const SizedBox(height: 4),
                Text(
                  lockedLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
