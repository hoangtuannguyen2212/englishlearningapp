import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/flashcard_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final String topicTitle;

  const LessonDetailScreen({super.key, required this.lesson, required this.topicTitle});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final GlobalKey<FlashcardWidgetState> _flashcardKey = GlobalKey<FlashcardWidgetState>();

  @override
  void initState() {
    super.initState();
    _fetchWords();
  }

  Future<void> _fetchWords() async {
    try {
      final wordIds = List<String>.from(widget.lesson['wordIds'] ?? []);
      if (wordIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('vocabularies')
          .where(FieldPath.documentId, whereIn: wordIds)
          .get();

      final wordMap = {
        for (var doc in snapshot.docs) doc.id: doc.data()..['id'] = doc.id
      };
      final ordered = wordIds
          .map((id) => wordMap[id])
          .whereType<Map<String, dynamic>>()
          .toList();

      setState(() {
        _words = ordered;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching words: $e");
      setState(() => _isLoading = false);
    }
  }

  void _goToNext() {
    _flashcardKey.currentState?.stopAudio();
    _flashcardKey.currentState?.resetFlip();
    if (_currentIndex < _words.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() => _currentIndex = 0);
    }
  }

  void _goToPrev() {
    if (_currentIndex > 0) {
      _flashcardKey.currentState?.stopAudio();
      _flashcardKey.currentState?.resetFlip();
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A56F6)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '${AppStrings.of(context).topicWithTitle(widget.topicTitle)} - ${AppStrings.of(context).lessonWithTitle(widget.lesson['title'] ?? '')}',
          style: const TextStyle(color: Color(0xFF2E384D), fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56F6)))
              : _words.isEmpty
                  ? Center(child: Text(AppStrings.of(context).noWordsFound, style: const TextStyle(fontSize: 16, color: Colors.grey)))
                  : Column(
                      children: [
                        // Progress
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: Row(
                            children: [
                              Text(
                                '${_currentIndex + 1} / ${_words.length}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E384D)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (_currentIndex + 1) / _words.length,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A56F6)),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Flashcard
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: FlashcardWidget(
                              key: _flashcardKey,
                              wordData: _words[_currentIndex],
                            ),
                          ),
                        ),

                        // Dot indicators
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_words.length, (i) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _currentIndex ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _currentIndex ? const Color(0xFF1A56F6) : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Navigation buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: _currentIndex > 0 ? _goToPrev : null,
                                icon: const Icon(Icons.arrow_back_ios_rounded),
                                color: const Color(0xFF1A56F6),
                                iconSize: 32,
                              ),
                              ElevatedButton(
                                onPressed: _goToNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A56F6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                child: Text(
                                  _currentIndex < _words.length - 1 ? AppStrings.of(context).next : AppStrings.of(context).complete,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed: _currentIndex < _words.length - 1 ? _goToNext : null,
                                icon: const Icon(Icons.arrow_forward_ios_rounded),
                                color: const Color(0xFF1A56F6),
                                iconSize: 32,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
