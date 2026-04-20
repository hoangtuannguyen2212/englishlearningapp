import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _vocabularyDatabase = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVocabularyFromFirebase();

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchVocabularyFromFirebase() async {
    try {
      // Để Firebase tự động xử lý Cache và Server thông minh nhất:
      // - Có mạng: Kéo bản cập nhật mới nhất từ Server về (Rất nhanh vì nó chỉ tải phần thay đổi).
      // - Mất mạng: Tự động lôi dữ liệu cũ từ Cache ra dùng.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vocabularies')
          .get();

      List<Map<String, dynamic>> loadedWords = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sắp xếp danh sách theo thứ tự A-Z cho đẹp mắt
      loadedWords.sort((a, b) => (a['word'] ?? '').toString().compareTo((b['word'] ?? '').toString()));

      setState(() {
        _vocabularyDatabase = loadedWords;
        _isLoading = false;
      });

      print("Đã tải và đồng bộ xong ${loadedWords.length} từ vựng");

    } catch (e) {
      print("Lỗi tải từ vựng: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      String name = user.email!.split('@')[0];
      return name.substring(0, 1).toUpperCase() + name.substring(1);
    }
    return "Guest";
  }

  String get _userAvatar {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      return user.email!.substring(0, 2).toUpperCase();
    }
    return "GU";
  }


  String _getShortType(String? type) {
    if (type == null || type.isEmpty) return "";
    switch (type.toLowerCase()) {
      case 'noun': return ' (n)';
      case 'verb': return ' (v)';
      case 'adjective': return ' (adj)';
      case 'adverb': return ' (adv)';
      case 'pronoun': return ' (pro)';
      case 'preposition': return ' (prep)';
      case 'conjunction': return ' (conj)';
      default: return ' ($type)';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc dựa trên trường 'word'
    List<Map<String, dynamic>> filteredWords = _vocabularyDatabase
        .where((item) => (item['word'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    bool isSearching = _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // PHẦN 1: HEADER & THANH TÌM KIẾM
            // ==========================================
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF1A56F6),
                          child: Text(_userAvatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, $_userName !',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E384D)),
                                ),
                                const SizedBox(height: 6),
                                const Row(
                                  children: [
                                    Icon(Icons.local_fire_department, size: 20, color: Color(0xFFFF5722)),
                                    SizedBox(width: 4),
                                    Text('12', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                                    SizedBox(width: 24),
                                    Icon(Icons.diamond, size: 18, color: Color(0xFF42A5F5)),
                                    SizedBox(width: 4),
                                    Text('234', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF42A5F5))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.notifications_none_outlined, size: 30, color: Color(0xFF1A56F6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FF),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: const TextStyle(color: Color(0xFFA8B1C3)),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1A56F6), size: 26),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              FocusScope.of(context).unfocus();
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // PHẦN 2: PHẦN THÂN (ẢNH NỀN VÀ KẾT QUẢ)
            // ==========================================
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/bg.jpg',
                    fit: BoxFit.cover,
                  ),

                  if (isSearching) ...[
                    GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),

                    Positioned(
                      top: 15,
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 10,
                        clipBehavior: Clip.antiAlias,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56F6)))
                            : filteredWords.isEmpty
                            ? Center(child: Text("Không tìm thấy từ: '$_searchQuery'", style: const TextStyle(color: Colors.grey, fontSize: 16)))
                            : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          itemCount: filteredWords.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1, height: 1),
                          itemBuilder: (context, index) {

                            // --- ĐÃ SỬA: Lấy thông tin từ vựng và từ loại ---
                            final wordData = filteredWords[index];
                            String word = wordData['word'] ?? '';
                            String type = wordData['type'] ?? '';
                            String shortType = _getShortType(type); // Gọi hàm rút gọn

                            return ListTile(
                              // --- ĐÃ SỬA: Dùng RichText thay cho Text thường ---
                              title: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 18),
                                  children: [
                                    TextSpan(
                                      text: word,
                                      style: const TextStyle(
                                        color: Color(0xFF2E384D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: shortType,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 15, // Cỡ chữ của (n), (v) nhỏ hơn 1 chút
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () {
                                FocusScope.of(context).unfocus(); // Cất bàn phím
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FlashcardScreen(
                                      wordData: wordData,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Container(color: Colors.transparent),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}