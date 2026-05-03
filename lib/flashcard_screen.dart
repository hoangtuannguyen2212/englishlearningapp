import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlashcardScreen extends StatefulWidget {
  final Map<String, dynamic> wordData;

  const FlashcardScreen({super.key, required this.wordData});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFront = true;

  // Trình phát âm thanh cho Audio URL có sẵn
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Trình đọc văn bản (Text-to-Speech)
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Cài đặt bộ điều khiển hiệu ứng lật
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Cấu hình giọng đọc TTS ban đầu
    _setupTts();
  }

  // Hàm cấu hình Text-to-Speech
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-UK"); // Đọc giọng tiếng Anh - Mỹ
    await _flutterTts.setSpeechRate(0.4);   // Tốc độ đọc
    await _flutterTts.setPitch(1.0);        // Độ trầm bổng
  }

  // Hàm gọi máy đọc văn bản
  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop(); // Bắt buộc tắt máy đọc khi thoát màn hình để không bị lặp âm
    super.dispose();
  }

  // Hàm phát âm thanh từ URL
  Future<void> _playSound(String url) async {
    if (url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có âm thanh cho từ này!')),
      );
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
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
        ),
      ),
    );
  }

  // ================= MẶT TRƯỚC =================
  Widget _buildFrontSide() {
    String word = widget.wordData['word'] ?? '';
    String type = widget.wordData['type'] ?? '';
    String phoneticUK = widget.wordData['phonetic_uk'] ?? '';
    String phoneticUS = widget.wordData['phonetic_us'] ?? '';

    return Container(
      width: double.infinity,
      height: 600,
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
              child: Text(type.toUpperCase(), style: const TextStyle(color: Color(0xFF1A56F6), fontWeight: FontWeight.bold)),
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
          const Text('Tap to see examples', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
              color: const Color(0xFF1A56F6).withOpacity(0.1),
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

// ================= MẶT SAU =================
  Widget _buildBackSide() {
    String definition = widget.wordData['definition'] ?? 'Chưa có định nghĩa';
    List<dynamic> examples = widget.wordData['examples'] ?? [];

    return Container(
      width: double.infinity,
      height: 600,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIÊU ĐỀ ĐỊNH NGHĨA (Đưa về chính giữa như cũ)
          const Center(
            child: Text(
                'Definition',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A56F6))
            ),
          ),
          const SizedBox(height: 12),

          // KHUNG CHỨA CÂU ĐỊNH NGHĨA & NÚT LOA
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
                // NỘI DUNG ĐỊNH NGHĨA (Đẩy sang trái)
                Expanded(
                  child: Text(
                    definition,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Color(0xFF2E384D), height: 1.4),
                    textAlign: TextAlign.left, // Căn trái cho đẹp khi có nút loa ở cuối
                  ),
                ),

                const SizedBox(width: 12), // Khoảng cách giữa chữ và loa

                // NÚT LOA MÀU CAM Ở CUỐI CÂU
                GestureDetector(
                  onTap: () => _speakText(definition),
                  child: Container(
                    margin: const EdgeInsets.only(top: 2), // Căn nhẹ cho icon ngang hàng chữ đầu tiên
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.15),
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

          // 2. PHẦN VÍ DỤ
          const Text(
              'Examples:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A56F6))
          ),
          const SizedBox(height: 12),

          Expanded(
            child: examples.isEmpty
                ? const Center(child: Text('Chưa có ví dụ cho từ này', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: examples.length,
              itemBuilder: (context, index) {
                String exampleText = examples[index].toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DẤU CHẤM TRÒN
                      const Text(
                          "• ",
                          style: TextStyle(fontSize: 20, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)
                      ),

                      // NỘI DUNG VÍ DỤ
                      Expanded(
                        child: Text(
                          exampleText,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF2E384D), height: 1.5),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // NÚT LOA MÀU XANH Ở CUỐI CÂU
                      GestureDetector(
                        onTap: () => _speakText(exampleText),
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A56F6).withOpacity(0.1),
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
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15)),
      ],
    );
  }
}