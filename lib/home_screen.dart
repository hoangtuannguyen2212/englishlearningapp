import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'flashcard_screen.dart'; // Đã import trang Flashcard

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
      QuerySnapshot snapshot;

      try {
        // 1. Thử lấy dữ liệu từ Bộ nhớ đệm (Cache) của điện thoại siêu nhanh
        snapshot = await FirebaseFirestore.instance
            .collection('vocabularies')
            .get(const GetOptions(source: Source.cache));

        // 2. Nếu Cache trống (Ví dụ: Lần đầu tiên người dùng tải app) -> Mới gọi lên Server
        if (snapshot.docs.isEmpty) {
          print("Chưa có Cache, đang tải 5000 từ từ Server (Chỉ tải 1 lần duy nhất)...");
          snapshot = await FirebaseFirestore.instance
              .collection('vocabularies')
              .get(const GetOptions(source: Source.server));
        } else {
          print("Đã lấy thành công 5000 từ từ Cache điện thoại! Siêu tốc!");
        }
      } catch (e) {
        // Dự phòng nếu có lỗi hệ thống, tự động fallback về Server
        snapshot = await FirebaseFirestore.instance.collection('vocabularies').get();
      }

      List<Map<String, dynamic>> loadedWords = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // (Tùy chọn) Sắp xếp danh sách theo thứ tự A-Z cho đẹp mắt
      loadedWords.sort((a, b) => (a['word'] ?? '').toString().compareTo((b['word'] ?? '').toString()));

      setState(() {
        _vocabularyDatabase = loadedWords;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    // Lọc dựa trên trường 'word' trong cục dữ liệu
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
                          hintText: 'Searching vocabulary',
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
                            return ListTile(
                              title: Text(
                                filteredWords[index]['word'] ?? '',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E384D)),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () {
                                FocusScope.of(context).unfocus(); // Cất bàn phím

                                // ĐÃ SỬA: Chuyển hướng sang màn hình Flashcard
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FlashcardScreen(
                                      wordData: filteredWords[index],
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