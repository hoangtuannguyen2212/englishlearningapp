import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

  // Trình phát âm thanh
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Cài đặt bộ điều khiển hiệu ứng lật (Tốc độ 400 mili-giây)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Tạo hiệu ứng xoay từ 0 đến 180 độ
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose(); // tắt loa khi thoát màn hình
    super.dispose();
  }

  // Hàm phát âm thanh
  Future<void> _playSound(String url) async {
    if (url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có âm thanh cho từ này!')),
      );
    }
  }

  // Hàm lật thẻ
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
      //Cho phép nền tràn viền lên phía sau AppBar
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A56F6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Flashcard', style: TextStyle(color: Color(0xFF2E384D), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      //Bọc toàn bộ Body bằng Container chứa hình nền
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Bạn có thể đổi tên ảnh ở đây nếu muốn dùng ảnh khác
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover, // Căn chỉnh ảnh phủ kín toàn bộ màn hình
          ),
        ),
        // SafeArea giúp thẻ flashcard không bị lẹm vào phần "tai thỏ" hoặc viền dưới điện thoại
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              // Bọc toàn bộ bằng GestureDetector để bắt sự kiện chạm lật thẻ
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    // Xoay quanh trục Y để tạo hiệu ứng 3D lật ngang
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Độ sâu perspective 3D
                      ..rotateY(_animation.value);

                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      // Nếu góc xoay > 90 độ (pi/2) thì hiển thị mặt sau, ngược lại hiển thị mặt trước
                      child: _animation.value >= (pi / 2)
                          ? Transform(
                        // Chống lật ngược chữ ở mặt sau (Lật lại 180 độ)
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

  // ================= MẶT TRƯỚC (Từ vựng, Loại từ, Phiên âm, Loa) =================
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
          // Loại từ
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

          // Từ vựng
          Text(
            word,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF2E384D)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Khu vực phiên âm và Loa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loa UK
              _buildAudioButton('UK', phoneticUK, widget.wordData['audio_uk']),
              const SizedBox(width: 40),
              // Loa US
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

  // Widget hiển thị nút bấm Loa và phiên âm
  Widget _buildAudioButton(String region, String phonetic, String? audioUrl) {
    return Column(
      children: [
        // Bấm vào nút này để nghe, ngăn sự kiện chạm lọt ra ngoài thẻ lật
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

  // ================= MẶT SAU (Danh sách ví dụ) =================
  Widget _buildBackSide() {
    List<dynamic> examples = widget.wordData['examples'] ?? [];

    return Container(
      width: double.infinity,
      height: 450,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Examples', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A56F6))),
          ),
          const Divider(height: 30, thickness: 2, color: Color(0xFFE3F2FD)),

          Expanded(
            child: examples.isEmpty
                ? const Center(child: Text('Chưa có ví dụ cho từ này', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: examples.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontSize: 20, color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          examples[index].toString(),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF2E384D), height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Center(
            child: Text('Chạm để quay lại mặt trước', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // Định dạng chung cho cả mặt trước và mặt sau của thẻ
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      // Chỉnh độ mờ nền thẻ một chút (0.95) để nhìn thấy ảnh nền lấp ló phía sau, tạo chiều sâu
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15)),
      ],
    );
  }
}