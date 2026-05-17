import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../courses/flashcard_screen.dart';
import 'review_words_screen.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_progress_model.dart';
import '../../data/services/srs_service.dart';
import '../../widgets/app_screen_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _vocabularyDatabase = [];
  bool _isLoading = true;
  final SRSService _srsService = SRSService();
  String? _activeUid;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _activeUid = FirebaseAuth.instance.currentUser?.uid;
    _fetchVocabularyFromFirebase();
    _searchFocusNode.addListener(() => setState(() {}));
    _authSub = FirebaseAuth.instance.userChanges().listen(_onUserChanged);
  }

  void _onUserChanged(User? user) {
    final uid = user?.uid;
    if (uid == _activeUid) return;
    _activeUid = uid;

    _searchController.clear();
    _searchFocusNode.unfocus();
    _searchQuery = '';

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchVocabularyFromFirebase() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('vocabularies').get();

      final loadedWords = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      loadedWords.sort(
        (a, b) =>
            (a['word'] ?? '').toString().compareTo((b['word'] ?? '').toString()),
      );

      setState(() {
        _vocabularyDatabase = loadedWords;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải từ vựng: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final strings = AppStrings.of(context);
    if (hour < 12) return strings.goodMorning;
    if (hour < 18) return strings.goodAfternoon;
    return strings.goodEvening;
  }

  String _getGreetingSubtitle(BuildContext context) {
    final hour = DateTime.now().hour;
    final strings = AppStrings.of(context);
    if (hour < 18) return strings.readyToLearn;
    return strings.letsReview;
  }

  String _getShortType(String? type) {
    if (type == null || type.isEmpty) return '';
    switch (type.toLowerCase()) {
      case 'noun':
        return ' (n)';
      case 'verb':
        return ' (v)';
      case 'adjective':
        return ' (adj)';
      case 'adverb':
        return ' (adv)';
      default:
        return ' ($type)';
    }
  }

  Map<String, dynamic>? _vocabById(String wordId) {
    for (final item in _vocabularyDatabase) {
      if (item['id'] == wordId) return item;
    }
    return null;
  }

  List<Map<String, dynamic>> _dueVocabularyList(List<WordProgress> dueProgress) {
    final List<Map<String, dynamic>> words = [];
    for (final progress in dueProgress) {
      final vocab = _vocabById(progress.wordId);
      if (vocab != null) words.add(vocab);
    }
    return words;
  }

  void _openReviewSession(List<Map<String, dynamic>> words) {
    if (words.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewWordsScreen(words: words),
      ),
    );
  }

  void _openFlashcard(Map<String, dynamic> wordData) {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(wordData: wordData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
              : null,
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final String displayName =
                userData?['username'] ?? user?.displayName ?? 'Learner';
            final int streak = userData?['streak'] ?? 0;
            final int diamond = UserModel.diamondFromMap(
              userData ?? const {},
            );

            final filteredWords = _vocabularyDatabase
                .where(
                  (item) => (item['word'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
                )
                .toList();

            final isSearching =
                _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;

            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  const AppScreenBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context, displayName, streak, diamond),
                        _buildSearchBar(context),
                        Expanded(
                          child: isSearching
                              ? _buildSearchResults(context, filteredWords)
                              : _buildReviewSection(context),
                        ),
                      ],
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

  Widget _buildHeader(
    BuildContext context,
    String name,
    int streak,
    int diamond,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting(context)}, $name!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E384D),
                  ),
                ),
                Text(
                  _getGreetingSubtitle(context),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatBadge(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                gradient: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
                glow: const Color(0xFFFF6D00),
              ),
              const SizedBox(height: 8),
              _buildStatBadge(
                icon: Icons.diamond_rounded,
                value: '$diamond',
                gradient: const [Color(0xFF42A5F5), Color(0xFF1A56F6)],
                glow: const Color(0xFF1A56F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required List<Color> gradient,
    required Color glow,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final s = AppStrings.of(context);
    final isFocused = _searchFocusNode.hasFocus;
    final isSearching = isFocused || _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF1A56F6)
                : Colors.white.withValues(alpha: 0.8),
            width: isFocused ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isFocused
                  ? const Color(0xFF1A56F6).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isFocused ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2E384D),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: s.searchHint,
            hintStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.38),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: isSearching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    color: const Color(0xFF1A56F6),
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1A56F6),
                      size: 26,
                    ),
                  ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<WordProgress>>(
      key: ValueKey('due_progress_$uid'),
      stream: _srsService.getDueProgressStream(),
      builder: (context, snapshot) {
        final dueProgress = snapshot.data ?? [];
        final dueWords = _dueVocabularyList(dueProgress);
        final dueCount = dueWords.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildReviewHeroCard(
              context,
              dueCount: dueCount,
              onStart: dueCount > 0 ? () => _openReviewSession(dueWords) : null,
            ),
            if (dueCount > 0) ...[
              const SizedBox(height: 20),
              ...dueWords.map(
                (word) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDueWordTile(context, word),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReviewHeroCard(
    BuildContext context, {
    required int dueCount,
    required VoidCallback? onStart,
  }) {
    final s = AppStrings.of(context);
    final bool hasDue = dueCount > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasDue
              ? const [Color(0xFF5C6BC0), Color(0xFF1A56F6)]
              : const [Color(0xFF90A4AE), Color(0xFF78909C)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56F6).withValues(alpha: hasDue ? 0.35 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.reviewWords,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.reviewWordsSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasDue ? s.wordsDueToday(dueCount) : s.noWordsDueToday,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (hasDue) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A56F6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  s.startReview,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDueWordTile(BuildContext context, Map<String, dynamic> wordData) {
    final String word = wordData['word'] ?? '';
    final String type = wordData['type'] ?? '';

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openFlashcard(wordData),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF1A56F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: word,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E384D),
                        ),
                      ),
                      TextSpan(
                        text: _getShortType(type),
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<Map<String, dynamic>> results) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A56F6)),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          AppStrings.of(context).noWordFound(_searchQuery),
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: results.length,
      separatorBuilder: (context, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final wordData = results[index];
        final String word = wordData['word'] ?? '';
        final String type = wordData['type'] ?? '';

        return Material(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: word,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E384D),
                    ),
                  ),
                  TextSpan(
                    text: _getShortType(type),
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            onTap: () => _openFlashcard(wordData),
          ),
        );
      },
    );
  }
}
