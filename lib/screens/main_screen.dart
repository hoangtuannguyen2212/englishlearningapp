import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'courses/courses_screen.dart';
import 'profile/profile_screen.dart';
import 'chatbot/ai_chatbot_screen.dart';
import '../core/localization/app_localizations.dart';
import '../data/services/gamification_service.dart';
import '../data/services/notification_service.dart';
import '../widgets/badge_unlock_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final PageController _pageController;
  final GamificationService _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addObserver(this);
    NotificationService().startFirestoreSync();
    _syncGamificationOnLaunch();
  }

  Future<void> _syncGamificationOnLaunch() async {
    await _gamificationService.migrateLegacyCurrencyFields();
    final newIds = await _gamificationService.checkBadges();
    if (!mounted || newIds.isEmpty) return;
    _showBadgeUnlocks(newIds);
  }

  void _showBadgeUnlocks(List<String> badgeIds) {
    final badges = _gamificationService.definitionsForIds(badgeIds);
    if (badges.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showBadgeUnlockDialog(context, badges: badges);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().syncFromFirestore();
      _syncGamificationOnLaunch();
    }
  }

  static const List<Widget> _pages = [
    _KeepAliveTab(child: HomeScreen()),
    _KeepAliveTab(child: CoursesScreen()),
    _KeepAliveTab(child: AIChatbotScreen()),
    _KeepAliveTab(child: ProfileScreen()),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const PageScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        elevation: 0,
        child: _AppBottomNavBar(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
          labels: [
            s.home,
            s.courses,
            s.aiChatbot,
            s.me,
          ],
        ),
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.labels,
  });

  static const Color _primary = Color(0xFF1A56F6);
  static const Color _inactive = Color(0xFF94A3B8);
  static const double _barHeight = 66;
  static const double _pillInset = 5;

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.diamond_rounded,
    Icons.person_rounded,
  ];

  /// Chỉ khung bo tròn trắng nổi — vùng ngoài trong suốt (nhìn xuyên ra nội dung tab).
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? bottomInset + 8 : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: SizedBox(
            height: _barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / labels.length;
                final pillWidth = tabWidth - _pillInset * 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: _pillInset + selectedIndex * tabWidth,
                      width: pillWidth,
                      top: _pillInset,
                      bottom: _pillInset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5B7CFA), Color(0xFF1A56F6)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(labels.length, (index) {
                        final selected = selectedIndex == index;
                        return Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: () => onTap(index),
                              child: SizedBox(
                                height: _barHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: selected ? 1.06 : 1,
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      child: Icon(
                                        _icons[index],
                                        size: 24,
                                        color:
                                            selected ? Colors.white : _inactive,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      height: 13,
                                      child: AnimatedOpacity(
                                        opacity: selected ? 1 : 0,
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Text(
                                          labels[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Giữ state từng tab khi vuốt sang tab khác (tương tự IndexedStack).
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
