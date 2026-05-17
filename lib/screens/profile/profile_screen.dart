import '../settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/badge_definition.dart';
import '../../data/models/user_model.dart';
import '../../data/services/gamification_service.dart';
import 'achievements_screen.dart';
import 'edit_profile_screen.dart';
import 'library_screen.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/profile_display_badges_row.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  String _getInitials(String? displayName, String? email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      List<String> names = displayName.trim().split(" ");
      if (names.length >= 2) {
        return (names[0][0] + names[names.length - 1][0]).toUpperCase();
      }
      return names[0][0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        final User? user = authSnapshot.data;

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null 
              ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
              : null,
          builder: (context, dbSnapshot) {
            final userData = dbSnapshot.data?.data() as Map<String, dynamic>?;
            final int totalXp = userData?['totalXp'] ?? 0;
            final int level = userData?['level'] ?? 1;
            final int streak = userData?['streak'] ?? 0;
            final int diamond = UserModel.diamondFromMap(
              userData ?? const {},
            );

            final gamification = GamificationService();
            final int currentThreshold = gamification.getXpThreshold(level);
            final int nextThreshold = gamification.getXpThreshold(level + 1);
            final int progressXp = totalXp - currentThreshold;
            final int neededXp = nextThreshold - currentThreshold;

            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  _buildBackground(),
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          _buildProfileHeader(
                            context,
                            user,
                            totalXp,
                            userData,
                          ),
                          const SizedBox(height: 20),
                          _buildStatsSection(
                            context,
                            streak: streak,
                            diamond: diamond,
                            level: level,
                            progressXp: progressXp,
                            neededXp: neededXp,
                          ),
                          const SizedBox(height: 24),
                          _buildMenuTile(
                            icon: Icons.library_books_outlined,
                            title: AppStrings.of(context).library,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LibraryScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.military_tech_outlined,
                            title: AppStrings.of(context).achievements,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AchievementsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.person_outline,
                            title: AppStrings.of(context).editProfile,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.settings_outlined,
                            title: AppStrings.of(context).settings,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.info_outline,
                            title: AppStrings.of(context).termsOfService,
                            onTap: () {},
                          ),
                          _buildMenuTile(
                            icon: Icons.privacy_tip_outlined,
                            title: AppStrings.of(context).privacyPolicy,
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _buildMenuTile(
                            icon: Icons.logout_rounded,
                            title: AppStrings.of(context).logOut,
                            iconColor: Colors.redAccent,
                            titleColor: Colors.redAccent,
                            onTap: () => _showLogoutConfirmation(context),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required int streak,
    required int diamond,
    required int level,
    required int progressXp,
    required int neededXp,
  }) {
    final s = AppStrings.of(context);
    final double progress =
        neededXp > 0 ? (progressXp / neededXp).clamp(0.0, 1.0) : 1.0;

    return Column(
      children: [
        _buildLevelCard(
          context,
          level: level,
          progress: progress,
          progressXp: progressXp,
          neededXp: neededXp,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGradientStatCard(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: s.streak,
                gradient: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
                glow: const Color(0xFFFF6D00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGradientStatCard(
                icon: Icons.diamond_rounded,
                value: '$diamond',
                label: s.diamond,
                gradient: const [Color(0xFF42A5F5), Color(0xFF1A56F6)],
                glow: const Color(0xFF1A56F6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required int level,
    required double progress,
    required int progressXp,
    required int neededXp,
  }) {
    final s = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF1A56F6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56F6).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.level,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$level',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.levelShort(level),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.xpToNextLevel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  neededXp > 0
                      ? s.xpProgress(progressXp, neededXp)
                      : s.xpProgress(progressXp, progressXp),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
    required Color glow,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildProfileHeader(
    BuildContext context,
    User? user,
    int totalXp,
    Map<String, dynamic>? userData,
  ) {
    final String displayName =
        user?.displayName ?? AppStrings.of(context).defaultUser;
    final String email = user?.email ?? AppStrings.of(context).noEmail;
    final String initials = _getInitials(user?.displayName, user?.email);
    final isEn = Provider.of<LocaleProvider>(context).isEnglish;
    final displayBadges = userData != null
        ? GamificationService.profileDisplayBadges(userData)
        : <BadgeDefinition>[];

    return Row(
      children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFF2962FF),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name & Email & Total XP
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: $totalXp XP',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  if (displayBadges.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: ProfileDisplayBadgesRow(
                        badges: displayBadges,
                        isEnglish: isEn,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final s = AppStrings.of(context, listen: false);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A56F6).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.logOutConfirm,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E384D),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.logOutDesc,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withValues(alpha: 0.5),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            foregroundColor: const Color(0xFF6B7280),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            s.cancel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await FirebaseAuth.instance.signOut();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            s.logOut,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final Color resolvedIconColor = iconColor ?? Colors.black87;
    final Color resolvedTitleColor = titleColor ?? Colors.black87;
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: resolvedIconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: resolvedTitleColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFF3F8FF),
            Colors.white,
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}
