import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:englishlearningapp/screens/courses/lesson_detail_screen.dart';
import 'package:englishlearningapp/core/localization/app_localizations.dart';

class LessonsScreen extends StatefulWidget {
  final Map<String, dynamic> topic;

  const LessonsScreen({super.key, required this.topic});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    try {
      final topicId = widget.topic['id'] as String;
      final snapshot = await FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('lessons')
          .orderBy('order')
          .get();

      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _lessons = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching lessons: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicTitle = widget.topic['title'] ?? AppStrings.of(context).lessonsLabel;

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
        title: Text(
          topicTitle,
          style: const TextStyle(
            color: Color(0xFF2E384D),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56F6)))
              : Column(
                  children: [
                    // Summary banner
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(Icons.book_outlined, '${widget.topic['totalLessons'] ?? 0}', AppStrings.of(context).lessonsLabel),
                          Container(width: 1, height: 30, color: Colors.grey.shade300),
                          _buildStat(Icons.abc, '${widget.topic['totalWords'] ?? 0}', AppStrings.of(context).wordsLabel),
                        ],
                      ),
                    ),
                    // Lesson list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          return _buildLessonTile(_lessons[index]);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1A56F6), size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2E384D))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildLessonTile(Map<String, dynamic> lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A56F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${lesson['order'] ?? ''}',
              style: const TextStyle(color: Color(0xFF1A56F6), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        title: Text(
          lesson['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2E384D)),
        ),
        subtitle: Text(
          AppStrings.of(context).words(lesson['totalWords'] ?? 0),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen(
                lesson: lesson,
                topicTitle: widget.topic['title'] ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}