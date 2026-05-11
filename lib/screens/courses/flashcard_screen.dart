import 'package:flutter/material.dart';
import '../../widgets/flashcard_widget.dart';

class FlashcardScreen extends StatelessWidget {
  final Map<String, dynamic> wordData;

  const FlashcardScreen({super.key, required this.wordData});

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
              child: SizedBox(
                height: 600,
                child: FlashcardWidget(wordData: wordData),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
