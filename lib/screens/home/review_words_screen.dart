import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/flashcard_widget.dart';
import '../../widgets/app_screen_background.dart';

class ReviewWordsScreen extends StatefulWidget {
  const ReviewWordsScreen({
    super.key,
    required this.words,
  });

  final List<Map<String, dynamic>> words;

  @override
  State<ReviewWordsScreen> createState() => _ReviewWordsScreenState();
}

class _ReviewWordsScreenState extends State<ReviewWordsScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AppScreenBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF1A56F6),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.reviewWords,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E384D),
                          ),
                        ),
                      ),
                      Text(
                        s.reviewProgress(_currentIndex + 1, widget.words.length),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A56F6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.words.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: FlashcardWidget(wordData: widget.words[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
