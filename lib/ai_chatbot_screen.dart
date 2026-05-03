import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
    // Khởi tạo Model Gemini với hướng dẫn hệ thống
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: 'AIzaSyDur16fCErc0hR49q7nZzcUsl0DaI8_wl0',
      systemInstruction: Content.system(
          "Bạn là một giáo viên dạy tiếng Anh nhiệt tình. "
              "Hãy trả lời bằng tiếng Việt nếu người dùng hỏi bằng tiếng Việt, "
              "nhưng luôn khuyến khích họ dùng tiếng Anh. Nếu họ viết sai ngữ pháp, hãy sửa lỗi cho họ."),
    );
    _chat = _model.startChat();

    _messages.add({
      'role': 'ai',
      'text': 'Xin chào! Tôi là trợ lý tiếng Anh của bạn. Bạn muốn học gì hôm nay?'
    });
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
      setState(() {
        _messages.add(
            {'role': 'ai', 'text': response.text ?? 'Tôi không hiểu ý bạn...'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Lỗi kết nối: $e'});
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
        title: const Text('AI Assistant',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1A56F6),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Delete chat history'),
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
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text']!, isUser);
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(
              color: Color(0xFF1A56F6)),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete history'),
        content: const Text('Are you sure you want to delete your entire chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _chat = _model.startChat(); // Khởi tạo lại phiên chat mới
      _messages.add({
        'role': 'ai',
        'text': 'Xin chào! Tôi là trợ lý tiếng Anh của bạn. Bạn muốn học gì hôm nay?'
      });
    });
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1A56F6) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: isUser
            ? Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
                  listBullet: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                  hintText: '...', border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Color(0xFF1A56F6)),
              onPressed: _sendMessage),
        ],
      ),
    );
  }
}