import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:englishlearningapp/core/localization/app_localizations.dart';

class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final String topicTitle;

  const LessonDetailScreen({super.key, required this.lesson, required this.topicTitle});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isFront = true;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _setupTts();
    _fetchWords();
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-UK");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);
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

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _playSound(String url) async {
    if (url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  void _flipCard() {
    if (_isFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    _isFront = !_isFront;
  }

  void _resetFlip() {
    if (!_isFront) {
      _animationController.reset();
      _isFront = true;
    }
  }

  void _goToNext() {
    if (_currentIndex < _words.length - 1) {
      _flutterTts.stop();
      _audioPlayer.stop();
      _resetFlip();
      setState(() => _currentIndex++);
    } else {
      _flutterTts.stop();
      _audioPlayer.stop();
      _resetFlip();
      setState(() => _currentIndex = 0);
    }
  }

  void _goToPrev() {
    if (_currentIndex > 0) {
      _flutterTts.stop();
      _audioPlayer.stop();
      _resetFlip();
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
          '${widget.topicTitle} - ${widget.lesson['title'] ?? ''}',
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
                            child: GestureDetector(
                              onTap: _flipCard,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  final transform = Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(_animation.value);
                                  return Transform(
                                    transform: transform,
                                    alignment: Alignment.center,
                                    child: _animation.value >= (pi / 2)
                                        ? Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.identity()..rotateY(pi),
                                            child: _buildBackSide(),
                                          )
                                        : _buildFrontSide(),
                                  );
                                },
                              ),
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

  Widget _buildFrontSide() {
    final word = _words[_currentIndex];
    String wordText = word['word'] ?? '';
    String type = word['type'] ?? '';
    String phoneticUK = word['phonetic_uk'] ?? '';
    String phoneticUS = word['phonetic_us'] ?? '';

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (type.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(type.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF1A56F6), fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 20),
          Text(
            wordText,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF2E384D)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAudioButton('UK', phoneticUK, word['audio_uk']),
              const SizedBox(width: 40),
              _buildAudioButton('US', phoneticUS, word['audio_us']),
            ],
          ),
          const Spacer(),
          Text(AppStrings.of(context).tapToSeeDefinition, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAudioButton(String region, String phonetic, String? audioUrl) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _playSound(audioUrl ?? ''),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up_rounded, color: Color(0xFF1A56F6), size: 20),
          ),
        ),
        const SizedBox(height: 12),
        Text(region, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        if (phonetic.isNotEmpty)
          Text(phonetic, style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildBackSide() {
    final word = _words[_currentIndex];
    String definition = word['definition'] ?? AppStrings.of(context).noDefinition;
    List<dynamic> examples = word['examples'] ?? [];

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(AppStrings.of(context).definition,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A56F6))),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD6E4FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    definition,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Color(0xFF2E384D), height: 1.4),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _speakText(definition),
                  child: Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF5722), size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3F2FD)),
          const SizedBox(height: 20),
          Text(AppStrings.of(context).examples,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A56F6))),
          const SizedBox(height: 12),
          Expanded(
            child: examples.isEmpty
                ? Center(child: Text(AppStrings.of(context).noExamples, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: examples.length,
                    itemBuilder: (context, index) {
                      String exampleText = examples[index].toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ",
                                style: TextStyle(fontSize: 20, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(exampleText,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF2E384D), height: 1.5)),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _speakText(exampleText),
                              child: Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A56F6).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.volume_up_rounded, color: Color(0xFF1A56F6), size: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 15)),
      ],
    );
  }
}