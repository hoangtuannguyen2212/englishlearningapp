import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/services/gamification_service.dart';
import '../../core/localization/app_localizations.dart';

enum QuizType { vocabularyToDefinition, fillInTheBlank, audioRecognition, wordScramble }

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final String lessonTitle;

  const QuizScreen({super.key, required this.words, required this.lessonTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;
  late List<QuizQuestion> _questions;
  final GamificationService _gamificationService = GamificationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // For Hint Feature
  Timer? _hintTimer;
  bool _showHintButton = false;

  // For Scramble Type
  List<String> _scrambledLetters = [];
  List<String> _userBuiltWord = [];

  @override
  void initState() {
    super.initState();
    _generateQuestions();
    _initQuestionState();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final types = QuizType.values;
    final random = Random();

    _questions = widget.words.map((word) {
      QuizType type = types[random.nextInt(types.length)];
      
      // If examples are empty, fallback to vocabularyToDefinition
      if (type == QuizType.fillInTheBlank && (word['examples'] == null || (word['examples'] as List).isEmpty)) {
        type = QuizType.vocabularyToDefinition;
      }
      
      // If audio is empty, fallback to vocabularyToDefinition
      if (type == QuizType.audioRecognition && (word['audio_uk'] == null && word['audio_us'] == null)) {
        type = QuizType.vocabularyToDefinition;
      }

      String question = "";
      List<String> options = [];
      String correctAnswer = "";

      if (type == QuizType.wordScramble) {
        question = "Unscramble the letters to spell: ${word['definition']}";
        correctAnswer = word['word'] ?? "";
      } else if (type == QuizType.fillInTheBlank) {
        String example = (word['examples'] as List).first.toString();
        question = example.replaceAll(RegExp(word['word'] as String, caseSensitive: false), "____");
        correctAnswer = word['word'] ?? "";
      } else if (type == QuizType.audioRecognition) {
        question = "Listen and choose the correct word";
        correctAnswer = word['word'] ?? "";
      } else {
        question = "What is the meaning of '${word['word']}'?";
        correctAnswer = word['definition'] ?? "";
      }

      if (type != QuizType.wordScramble) {
        options = [correctAnswer];
        List<Map<String, dynamic>> others = widget.words.where((w) => w['id'] != word['id']).toList();
        others.shuffle();
        for (var i = 0; i < min(3, others.length); i++) {
          if (type == QuizType.vocabularyToDefinition) {
            options.add(others[i]['definition'] ?? "Alternative");
          } else {
            options.add(others[i]['word'] ?? "Alternative");
          }
        }
        while (options.length < 4) {
          options.add(type == QuizType.vocabularyToDefinition ? "Meaning ${options.length}" : "Word ${options.length}");
        }
        options.shuffle();
      }

      return QuizQuestion(
        type: type,
        question: question,
        correctAnswerIndex: type != QuizType.wordScramble ? options.indexOf(correctAnswer) : -1,
        options: options,
        wordData: word,
        correctAnswer: correctAnswer,
      );
    }).toList();
    _questions.shuffle();
  }

  void _initQuestionState() {
    _isAnswered = false;
    _selectedAnswerIndex = null;
    _showHintButton = false;
    _stopHintTimer();

    final q = _questions[_currentQuestionIndex];
    
    if (q.type == QuizType.wordScramble) {
      _userBuiltWord = [];
      _scrambledLetters = q.correctAnswer.split('')..shuffle();
      _startHintTimer();
    }
  }

  void _startHintTimer() {
    _stopHintTimer();
    _hintTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_isAnswered && _scrambledLetters.isNotEmpty) {
        setState(() {
          _showHintButton = true;
        });
      }
    });
  }

  void _stopHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  void _useHint() {
    if (_isAnswered || _scrambledLetters.isEmpty) return;

    final q = _questions[_currentQuestionIndex];
    String correctWord = q.correctAnswer;
    int nextIndex = _userBuiltWord.length;

    if (nextIndex >= correctWord.length) return;

    String neededLetter = correctWord[nextIndex];
    
    // Find this letter in scrambled list (case insensitive comparison if needed, but here they should match)
    int foundIndex = -1;
    for (int i = 0; i < _scrambledLetters.length; i++) {
      if (_scrambledLetters[i].toLowerCase() == neededLetter.toLowerCase()) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex != -1) {
      setState(() {
        _userBuiltWord.add(_scrambledLetters.removeAt(foundIndex));
        _showHintButton = false;
        
        if (_scrambledLetters.isEmpty) {
          _isAnswered = true;
          _stopHintTimer();
          if (_userBuiltWord.join('').toLowerCase() == q.correctAnswer.toLowerCase()) {
            _score += 10;
          }
          _nextQuestion();
        } else {
          _startHintTimer(); // Start next 10s for another hint
        }
      });
    }
  }

  void _handleAnswer(int index) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == _questions[_currentQuestionIndex].correctAnswerIndex) {
        _score += 10;
      }
    });

    _nextQuestion();
  }

  void _handleScrambleLetterTap(int index) {
    if (_isAnswered) return;
    setState(() {
      _userBuiltWord.add(_scrambledLetters.removeAt(index));
      _showHintButton = false;
      _startHintTimer(); // Reset timer on manual tap

      if (_scrambledLetters.isEmpty) {
        _isAnswered = true;
        _stopHintTimer();
        if (_userBuiltWord.join('').toLowerCase() == _questions[_currentQuestionIndex].correctAnswer.toLowerCase()) {
          _score += 10;
        }
        _nextQuestion();
      }
    });
  }

  void _undoScrambleLetter() {
    if (_isAnswered || _userBuiltWord.isEmpty) return;
    setState(() {
      _scrambledLetters.add(_userBuiltWord.removeLast());
    });
  }

  void _nextQuestion() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _initQuestionState();
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _finishQuiz() async {
    await _gamificationService.addRewards(_score);
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            Text(AppStrings.of(context).wellDone, textAlign: TextAlign.center, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Quiz Completed!", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardBadge(Icons.stars, "+$_score", "XP", Colors.blue),
                const SizedBox(width: 24),
                _buildRewardBadge(Icons.monetization_on, "+$_score", "Coins", Colors.orange),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var q = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: Text("Smart Quiz: ${widget.lessonTitle}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A56F6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildQuestionContent(q),
                  const SizedBox(height: 40),
                  if (q.type == QuizType.wordScramble) _buildScrambleUI(q) else _buildOptionsUI(q),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(QuizQuestion q) {
    if (q.type == QuizType.audioRecognition) {
      return Column(
        children: [
          const Text("Listen carefully:", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final url = q.wordData['audio_uk'] ?? q.wordData['audio_us'];
              if (url != null) _audioPlayer.play(UrlSource(url));
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
              ]),
              child: const Icon(Icons.volume_up_rounded, size: 48, color: Color(0xFF1A56F6)),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Text(
        q.question,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5, color: Color(0xFF2E384D)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOptionsUI(QuizQuestion q) {
    return Column(
      children: List.generate(q.options.length, (index) {
        bool isCorrect = index == q.correctAnswerIndex;
        bool isSelected = index == _selectedAnswerIndex;
        
        Color color = Colors.white;
        Color borderColor = Colors.grey.shade200;
        if (_isAnswered) {
          if (isCorrect) {
            color = Colors.green.shade50;
            borderColor = Colors.green;
          } else if (isSelected) {
            color = Colors.red.shade50;
            borderColor = Colors.red;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _handleAnswer(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected ? borderColor : Colors.grey.shade100,
                    child: Text(String.fromCharCode(65 + index), 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      q.options[index],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E384D)),
                    ),
                  ),
                  if (_isAnswered && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                  if (_isAnswered && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildScrambleUI(QuizQuestion q) {
    return Column(
      children: [
        // Built word display
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: _userBuiltWord.map((l) => _buildLetterTile(l, true)).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _undoScrambleLetter,
              icon: const Icon(Icons.undo, size: 16),
              label: const Text("Undo"),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
            ),
            if (_showHintButton) ...[
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _useHint,
                icon: const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                label: const Text("Hint", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        // Scrambled letters
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_scrambledLetters.length, (index) {
            return _buildLetterTile(_scrambledLetters[index], false, onTap: () => _handleScrambleLetterTap(index));
          }),
        ),
      ],
    );
  }

  Widget _buildLetterTile(String letter, bool isBuilt, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBuilt ? const Color(0xFF1A56F6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          border: Border.all(color: isBuilt ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isBuilt ? Colors.white : const Color(0xFF2E384D)),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final QuizType type;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final Map<String, dynamic> wordData;
  final String correctAnswer;

  QuizQuestion({
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.wordData,
    required this.correctAnswer,
  });
}
