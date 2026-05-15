import 'package:cloud_firestore/cloud_firestore.dart';

class WordProgress {
  final String wordId;
  final int repetition;
  final double easeFactor;
  final int interval;
  final DateTime nextReview;
  final DateTime? lastReview;

  WordProgress({
    required this.wordId,
    this.repetition = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    required this.nextReview,
    this.lastReview,
  });

  factory WordProgress.fromFirestore(Map<String, dynamic> data) {
    return WordProgress(
      wordId: data['wordId'] ?? '',
      repetition: data['repetition'] ?? 0,
      easeFactor: (data['easeFactor'] ?? 2.5).toDouble(),
      interval: data['interval'] ?? 0,
      nextReview: (data['nextReview'] as Timestamp).toDate(),
      lastReview: data['lastReview'] != null 
          ? (data['lastReview'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wordId': wordId,
      'repetition': repetition,
      'easeFactor': easeFactor,
      'interval': interval,
      'nextReview': Timestamp.fromDate(nextReview),
      'lastReview': lastReview != null ? Timestamp.fromDate(lastReview!) : null,
    };
  }
}
