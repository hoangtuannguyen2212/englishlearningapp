import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/services/srs_service.dart';
import '../../data/models/user_progress_model.dart';
import '../courses/flashcard_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final SRSService _srsService = SRSService();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final strings = AppStrings.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.library)),
        body: Center(child: Text(strings.notLoggedIn)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          strings.myVocabulary,
          style: const TextStyle(color: Color(0xFF2E384D), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2962FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('user_progress')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      strings.noWordsFound,
                      style: const TextStyle(color: Colors.black45),
                    ),
                  );
                }

                final List<WordProgress> allProgress = snapshot.data!.docs
                    .map((doc) => WordProgress.fromFirestore(doc.data() as Map<String, dynamic>))
                    .toList();

                // Apply filter
                final filteredProgress = allProgress.where((p) {
                  if (_selectedFilter == 'All') return true;
                  return _srsService.getStatusFromProgress(p) == _selectedFilter;
                }).toList();

                if (filteredProgress.isEmpty) {
                  return const Center(
                    child: Text("No words in this category", style: TextStyle(color: Colors.black45)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: filteredProgress.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final progress = filteredProgress[index];
                    return _buildWordTile(progress);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          _filterChip('All', Colors.blueGrey),
          const SizedBox(width: 8),
          _filterChip('New', Colors.red),
          const SizedBox(width: 8),
          _filterChip('Hard', Colors.orange),
          const SizedBox(width: 8),
          _filterChip('Easy', Colors.green),
        ],
      ),
    );
  }

  Widget _filterChip(String label, Color color) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildWordTile(WordProgress progress) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('vocabularies').doc(progress.wordId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 70);

        final wordData = snapshot.data!.data() as Map<String, dynamic>?;
        if (wordData == null) return const SizedBox.shrink();
        
        wordData['id'] = snapshot.data!.id;
        final String word = wordData['word'] ?? "";
        final String type = wordData['type'] ?? "";
        final String status = _srsService.getStatusFromProgress(progress);
        
        Color statusColor = Colors.grey;
        if (status == "Easy") statusColor = Colors.green;
        if (status == "Hard") statusColor = Colors.orange;
        if (status == "New") statusColor = Colors.red;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(
                  word,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  "($type)",
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black45),
                ),
              ],
            ),
            subtitle: Text(
              "Interval: ${progress.interval} days",
              style: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashcardScreen(wordData: wordData),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
