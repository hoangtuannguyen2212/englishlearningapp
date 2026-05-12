import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/localization/app_localizations.dart';

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
          const Spacer(),
          Text(AppStrings.of(context).tapToSeeDefinition,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
