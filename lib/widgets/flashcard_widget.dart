import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/localization/app_localizations.dart';
import '../data/services/gamification_service.dart';
import '../data/services/srs_service.dart';

class FlashcardWidget extends StatefulWidget {
  final Map<String, dynamic> wordData;

  const FlashcardWidget({super.key, required this.wordData});

  @override
  State<FlashcardWidget> createState() => FlashcardWidgetState();
}

class FlashcardWidgetState extends State<FlashcardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFront = true;
  String _localStatus = "None";
  StreamSubscription? _statusSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final SRSService _srsService = SRSService();

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
    _initLocalStatus();
  }

  void _initLocalStatus() {
    String wordId = widget.wordData['id'] ?? '';
    _statusSubscription = _srsService.getWordProgressStream(wordId).listen((progress) {
      if (mounted) {
        setState(() {
          _localStatus = _srsService.getStatusFromProgress(progress);
        });
      }
    });
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-UK");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _playSound(String url) async {
    if (url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  void flipCard() {
    if (_isFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    _isFront = !_isFront;
  }

  void resetFlip() {
    if (!_isFront) {
      _animationController.reset();
      _isFront = true;
    }
  }

  void stopAudio() {
    _flutterTts.stop();
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flipCard,
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
    );
  }

  Widget _buildFrontSide() {
    String word = widget.wordData['word'] ?? '';
    String type = widget.wordData['type'] ?? '';
    String phoneticUK = widget.wordData['phonetic_uk'] ?? '';
    String phoneticUS = widget.wordData['phonetic_us'] ?? '';
    String wordId = widget.wordData['id'] ?? '';

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Stack(
        children: [
          // Interactive Status Tags (Sliding Selector)
          Positioned(
            top: 20,
            left: 30,
            right: 30,
            child: _buildSlidingStatusSelector(_localStatus, wordId),
          ),
          
          Center(
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
                  word,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF2E384D)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAudioButton('UK', phoneticUK, widget.wordData['audio_uk']),
                    const SizedBox(width: 40),
                    _buildAudioButton('US', phoneticUS, widget.wordData['audio_us']),
                  ],
                ),
                const SizedBox(height: 40),
                Text(AppStrings.of(context).tapToSeeDefinition,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingStatusSelector(String currentStatus, String wordId) {
    final List<String> statuses = ["New", "Hard", "Easy"];
    final List<Color> colors = [Colors.red, Colors.orange, Colors.green];
    
    int selectedIndex = statuses.indexOf(currentStatus);
    // Nếu status là "None", chúng ta có thể mặc định là không hiển thị con chạy hoặc để ở vị trí New nhưng mờ
    bool isNone = selectedIndex == -1;
    if (isNone) selectedIndex = 0;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Con chạy (Sliding Indicator)
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack,
            alignment: Alignment(
              isNone ? -2.0 : (selectedIndex * 1.0 - 1.0), // Map 0,1,2 to -1, 0, 1
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isNone ? Colors.transparent : colors[selectedIndex],
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isNone ? [] : [
                    BoxShadow(
                      color: colors[selectedIndex].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Các nhãn chữ
          Row(
            children: List.generate(statuses.length, (index) {
              bool isSelected = !isNone && selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final String nextStatus = (currentStatus == statuses[index]) ? "None" : statuses[index];
                    
                    // Optimistic UI Update: Cập nhật ngay lập tức giao diện
                    setState(() {
                      _localStatus = nextStatus;
                    });
                    
                    // Xử lý ngầm database, không block UI
                    _srsService.updateStatus(wordId, nextStatus).then((_) {
                      if (nextStatus == 'Easy' || nextStatus == 'Hard') {
                        GamificationService().recordSrsReview();
                      }
                    });
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black45,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      child: Text(statuses[index].toUpperCase()),
                    ),
                  ),
                ),
              );
            }),
          ),
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
    String definition = widget.wordData['definition'] ?? AppStrings.of(context).noDefinition;
    List<dynamic> examples = widget.wordData['examples'] ?? [];

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
                    style: const TextStyle(
                        fontSize: 16, fontStyle: FontStyle.italic, color: Color(0xFF2E384D), height: 1.4),
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
          const SizedBox(height: 10),
          Text(AppStrings.of(context).examples,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A56F6))),
          const SizedBox(height: 8),
          Expanded(
            child: examples.isEmpty
                ? Center(child: Text(AppStrings.of(context).noExamples, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: examples.length,
                    itemBuilder: (context, index) {
                      String exampleText = examples[index].toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
