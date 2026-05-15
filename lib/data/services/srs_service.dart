import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_progress_model.dart';
import 'notification_service.dart';

class SRSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // quality mapping: Hard -> 1, Easy -> 3
  WordProgress calculateNextReview(WordProgress current, int quality) {
    int n = current.repetition;
    double ef = current.easeFactor;
    int i = current.interval;

    if (quality == 3) { // Easy
      i = 4; // Luôn là 4 ngày cho Easy
      n++;
      ef = ef + 0.1;
    } else if (quality == 1) { // Hard
      i = 2; // Luôn là 2 ngày cho Hard
      n++;
      ef = ef - 0.2;
    } else { // New/Reset (quality 0)
      n = 0;
      i = 1; // Luôn là 1 ngày cho New
      ef = 2.5;
    }

    if (ef < 1.3) ef = 1.3;
    if (ef > 3.5) ef = 3.5;

    final now = DateTime.now();
    final reviewDay = DateTime(now.year, now.month, now.day)
        .add(Duration(days: i));
    // 9:00 sáng — dễ nhận thông báo hơn 00:00, alarm Android ổn định hơn.
    final nextReview = DateTime(
      reviewDay.year,
      reviewDay.month,
      reviewDay.day,
      9,
      0,
    );

    return WordProgress(
      wordId: current.wordId,
      repetition: n,
      easeFactor: ef,
      interval: i,
      nextReview: nextReview,
      lastReview: now,
    );
  }

  Future<void> updateStatus(String wordId, String status) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('user_progress')
        .doc(wordId);

    final snapshot = await docRef.get();
    WordProgress progress;

    if (snapshot.exists) {
      progress = WordProgress.fromFirestore(snapshot.data()!);
      // Nếu trạng thái mới trùng với trạng thái hiện tại (dựa trên interval cũ)
      // thì không làm gì để tránh việc nhấn liên tục làm tăng interval vô lý.
      String currentStatus = getStatusFromProgress(progress);
      if (currentStatus == status) return;
    } else {
      progress = WordProgress(
        wordId: wordId,
        nextReview: DateTime.now(),
      );
    }

    int quality;
    if (status == "Easy") {
      quality = 3;
    } else if (status == "Hard") {
      quality = 1;
    } else if (status == "New") {
      quality = 0;
    } else {
      // Nếu là "None" hoặc trạng thái khác, xóa bản ghi tiến trình (Reset hoàn toàn)
      await docRef.delete();
      await NotificationService().scheduleNextReviewReminder(force: true);
      return;
    }

    final nextProgress = calculateNextReview(progress, quality);
    await docRef.set(nextProgress.toFirestore());

    await NotificationService().scheduleReminderAt(
      nextProgress.nextReview,
      force: true,
    );
  }

  Stream<WordProgress?> getWordProgressStream(String wordId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('user_progress')
        .doc(wordId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return WordProgress.fromFirestore(snapshot.data()!);
          }
          return null;
        });
  }

  Stream<int> getDueCountStream() => getDueProgressStream().map((list) => list.length);

  /// Từ có [nextReview] đến hạn (<= thời điểm hiện tại).
  Stream<List<WordProgress>> getDueProgressStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('user_progress')
        .where('nextReview', isLessThanOrEqualTo: DateTime.now())
        .orderBy('nextReview')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WordProgress.fromFirestore(doc.data()))
              .toList();
        });
  }

  /// Thời điểm ôn sớm nhất trong [user_progress].
  Future<DateTime?> getNextReviewTime({bool fromServer = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('user_progress')
        .orderBy('nextReview')
        .limit(1)
        .get(
          fromServer
              ? const GetOptions(source: Source.server)
              : null,
        );

    if (snapshot.docs.isEmpty) return null;

    return (snapshot.docs.first.data()['nextReview'] as Timestamp).toDate();
  }

  String getStatusFromProgress(WordProgress? progress) {
    if (progress == null || progress.lastReview == null) return "None";
    if (progress.interval >= 4) return "Easy";
    if (progress.interval >= 2) return "Hard";
    if (progress.interval == 1) return "New";
    return "None";
  }
}
