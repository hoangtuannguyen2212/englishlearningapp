import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'lessons_screen.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_screen_background.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Map<String, dynamic>> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('topics')
          .get();
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _topics = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching topics: $e");
      setState(() => _isLoading = false);
    }
  }

  IconData _topicIcon(String? id) {
    switch (id) {
      case 'topic_education':
        return Icons.school_outlined;
      case 'topic_food':
        return Icons.restaurant_outlined;
      case 'topic_health':
        return Icons.favorite_outline;
      case 'topic_it':
        return Icons.computer_outlined;
      case 'topic_travel':
        return Icons.flight_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _topicColor(String? id) {
    switch (id) {
      case 'topic_education':
        return const Color(0xFF1A56F6);
      case 'topic_food':
        return const Color(0xFFFF5722);
      case 'topic_health':
        return const Color(0xFFE91E63);
      case 'topic_it':
        return const Color(0xFF00BCD4);
      case 'topic_travel':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF1A56F6);
    }
  }

  String _translateTopicTitle(String? id, bool isEnglish) {
    if (isEnglish) {
      switch (id) {
        case 'topic_education':
          return 'Education';
        case 'topic_food':
          return 'Food';
        case 'topic_health':
          return 'Health';
        case 'topic_it':
          return 'IT';
        case 'topic_travel':
          return 'Travel';
        default:
          return 'Topics';
      }
    } else {
      switch (id) {
        case 'topic_education':
          return 'Giáo dục';
        case 'topic_food':
          return 'Ẩm thực';
        case 'topic_health':
          return 'Sức khỏe';
        case 'topic_it':
          return 'Công nghệ';
        case 'topic_travel':
          return 'Du lịch';
        default:
          return 'Chủ đề';
      }
    }
  }

  String _translateTopicDescription(String? id, bool isEnglish) {
    if (isEnglish) {
      switch (id) {
        case 'topic_education':
          return 'Learn education vocabulary';
        case 'topic_food':
          return 'Learn food and cooking terms';
        case 'topic_health':
          return 'Learn health and wellness words';
        case 'topic_it':
          return 'Learn technology vocabulary';
        case 'topic_travel':
          return 'Learn travel and tourism words';
        default:
          return 'Learn vocabulary';
      }
    } else {
      switch (id) {
        case 'topic_education':
          return 'Học từ vựng về giáo dục';
        case 'topic_food':
          return 'Học từ vựng về ẩm thực';
        case 'topic_health':
          return 'Học từ vựng về sức khỏe';
        case 'topic_it':
          return 'Học từ vựng công nghệ';
        case 'topic_travel':
          return 'Học từ vựng về du lịch';
        default:
          return 'Học từ vựng';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AppScreenBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  AppStrings.of(context).courses,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E384D),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.of(context).chooseTopicToLearn,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A56F6),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: _topics.length,
                        itemBuilder: (context, index) {
                          return _buildTopicCard(_topics[index]);
                        },
                      ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final color = _topicColor(topic['id']);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final translatedTitle = _translateTopicTitle(
      topic['id'],
      localeProvider.isEnglish,
    );
    final translatedDescription = _translateTopicDescription(
      topic['id'],
      localeProvider.isEnglish,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LessonsScreen(topic: topic)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_topicIcon(topic['id']), color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              translatedTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E384D),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              translatedDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.book_outlined, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  AppStrings.of(context).lessons(topic['totalLessons'] ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.abc, size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  AppStrings.of(context).words(topic['totalWords'] ?? 0),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}