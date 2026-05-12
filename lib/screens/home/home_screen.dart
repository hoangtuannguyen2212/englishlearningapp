import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../courses/flashcard_screen.dart';
import '../../core/localization/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchVocabularyFromFirebase();

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchVocabularyFromFirebase() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vocabularies')
          .get();

      List<Map<String, dynamic>> loadedWords = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      loadedWords.sort((a, b) => (a['word'] ?? '').toString().compareTo((b['word'] ?? '').toString()));

      setState(() {
        _vocabularyDatabase = loadedWords;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải từ vựng: $e");
      setState(() {
        _isLoading = false;
      });
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
    if (type == null || type.isEmpty) return "";
    switch (type.toLowerCase()) {
      case 'noun': return ' (n)';
      case 'verb': return ' (v)';
      case 'adjective': return ' (adj)';
      case 'adverb': return ' (adv)';
      default: return ' ($type)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null 
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final String displayName = userData?['username'] ?? user?.displayName ?? "Learner";
        final int streak = userData?['streak'] ?? 0;
        final int coins = userData?['coins'] ?? 0;

        List<Map<String, dynamic>> filteredWords = _vocabularyDatabase
            .where((item) => (item['word'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        bool isSearching = _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              _buildBackgroundGradient(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, displayName, streak, coins),
                    _buildSearchBox(context),
                    Expanded(
                      child: isSearching 
                          ? _buildSearchResults(context, filteredWords)
                          : _buildDashboard(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundGradient() {
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

  Widget _buildHeader(BuildContext context, String name, int streak, int coins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
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
          _buildStatIcon(Icons.local_fire_department, "$streak", Colors.orange),
          const SizedBox(width: 16),
          _buildStatIcon(Icons.diamond, "$coins", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E384D),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    bool isSearching = _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: AppStrings.of(context).search,
            hintStyle: const TextStyle(color: Colors.black38),
            prefixIcon: isSearching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2962FF)),
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : const Icon(Icons.search, color: Color(0xFF2962FF)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 10),
        _buildDashboardCard(
          title: strings.wordOfTheDay,
          content: _vocabularyDatabase.isNotEmpty 
              ? _vocabularyDatabase[DateTime.now().day % _vocabularyDatabase.length]['word'] 
              : "Inspire",
          icon: Icons.lightbulb_outline,
          color: Colors.orangeAccent,
          onTap: () {
            if (_vocabularyDatabase.isNotEmpty) {
              _openFlashcard(_vocabularyDatabase[DateTime.now().day % _vocabularyDatabase.length]);
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          title: strings.dailyChallenge,
          content: strings.letsReview,
          icon: Icons.star_outline,
          color: Colors.purpleAccent,
          onTap: () {
            // Placeholder for challenge
          },
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          title: strings.continueLearning,
          content: "Travel & Food",
          icon: Icons.play_circle_outline,
          color: Colors.greenAccent,
          onTap: () {
            // Placeholder for continue
          },
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E384D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<Map<String, dynamic>> results) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final wordData = results[index];
        final String word = wordData['word'] ?? "";
        final String type = wordData['type'] ?? "";
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: word,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E384D),
                  ),
                ),
                TextSpan(
                  text: _getShortType(type),
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          onTap: () => _openFlashcard(wordData),
        );
      },
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
}
