import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/localization/app_localizations.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  late GenerativeModel _model;
  late ChatSession _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initModel();
    _loadChatHistory();
  }

  void _initModel() {
    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    // Khởi tạo Model Gemini với hướng dẫn hệ thống
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are an enthusiastic English teacher. "
          "Always encourage the user to use English. If they write in Vietnamese, respond in Vietnamese but include English translations. "
          "Always correct their grammar mistakes politely."),
    );
    _chat = _model.startChat();
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedHistory = prefs.getString('chat_history');

    if (savedHistory != null) {
      setState(() {
        _messages.clear();
        final List<dynamic> decoded = jsonDecode(savedHistory);
        _messages.addAll(decoded.map((item) => Map<String, String>.from(item)).toList());
      });
      _scrollToBottom();
    } else {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': AppStrings.of(context, listen: false).chatbotGreeting
        });
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }

    String userText = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(userText));
      if (!mounted) return;
      
      setState(() {
        _messages.add(
            {'role': 'ai', 'text': response.text ?? AppStrings.of(context, listen: false).chatbotFallback});
      });
      _saveChatHistory();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = AppStrings.of(context, listen: false).connectionError(e.toString());
      if (e.toString().contains('503')) {
        errorMessage = AppStrings.of(context, listen: false).aiOverloaded;
      } else if (e.toString().contains('429')) {
        errorMessage = AppStrings.of(context, listen: false).tooManyRequests;
      }

      setState(() {
        _messages.add({'role': 'ai', 'text': errorMessage});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: Column(
          children: [
            Text(AppStrings.of(context).aiAssistant,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                SizedBox(width: 4),
                Text('Online', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A56F6),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.of(context, listen: false).clearChatHistory,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text']!, isUser);
              },
            ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
              ],
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A56F6)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI is typing...',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Biểu tượng thùng rác nổi bật
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề
              Text(
                AppStrings.of(context).clearChatConfirm,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E384D),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                AppStrings.of(context).clearChatDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Hai nút bấm Hủy và Xóa
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        AppStrings.of(context).cancel,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearChat();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppStrings.of(context).delete,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _chat = _model.startChat(); // Khởi tạo lại phiên chat mới
      _messages.add({
        'role': 'ai',
        'text': AppStrings.of(context, listen: false).chatbotGreeting
      });
      _saveChatHistory();
    });
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1A56F6),
                child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1A56F6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: isUser
                  ? Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))
                  : MarkdownBody(
                      data: text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Color(0xFF2E384D), fontSize: 15, height: 1.5),
                        listBullet: const TextStyle(color: Color(0xFF2E384D), fontSize: 15),
                      ),
                    ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE3EDFF)),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A56F6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x4D1A56F6), blurRadius: 8, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
