import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'srs_service.dart';

class NotificationService {
  static const String _channelId = 'vocabulary_reminder_v2';
  static const String _channelName = 'Vocabulary Reminders';
  static const int _reminderNotificationId = 100;
  static const int _testNotificationId = 999;

  static const String _prefLastReminderMillis = 'last_reminder_scheduled_millis';
  static const String _prefDueReminderMillis = 'due_reminder_fire_at_millis';
  static const String _prefLastSourceNextReviewMillis =
      'last_source_next_review_millis';
  static const String _prefHandledDueSourceMillis = 'handled_due_source_millis';
  static const String _prefNotificationsOn = 'notifications_on';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SRSService _srsService = SRSService();

  bool _initialized = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
  Timer? _syncDebounce;
  DateTime? _lastScheduledFireAt;

  Future<void> init() async {
    if (_initialized) return;

    await _configureLocalTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_notification');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createAndroidChannel();
    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] tapped: ${response.payload}');
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders to review vocabulary',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to review vocabulary',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          autoCancel: true,
          ongoing: false,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  Future<bool> _isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotificationsOn) ?? false;
  }

  DateTime? get lastScheduledFireAt => _lastScheduledFireAt;

  /// Lắng nghe Firestore — tự hẹn lại khi [nextReview] đổi (kể cả sửa trên Firebase Console).
  Future<void> startFirestoreSync() async {
    await stopFirestoreSync();
    if (!await _isNotificationsEnabled()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await scheduleNextReviewReminder(force: true, fromServer: false);

    _firestoreSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('user_progress')
        .snapshots()
        .listen((_) => _debouncedSyncFromFirestore());
  }

  Future<void> stopFirestoreSync() async {
    _syncDebounce?.cancel();
    _syncDebounce = null;
    await _firestoreSub?.cancel();
    _firestoreSub = null;
  }

  void _debouncedSyncFromFirestore() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 400), () {
      scheduleNextReviewReminder(force: false, fromServer: false);
    });
  }

  Future<bool> syncFromFirestore() =>
      scheduleNextReviewReminder(force: false, fromServer: false);

  Future<bool> scheduleNextReviewReminder({
    bool force = false,
    bool fromServer = false,
  }) async {
    final DateTime? next =
        await _srsService.getNextReviewTime(fromServer: fromServer);
    if (next == null) return false;

    if (!force && await _shouldSkipReschedule(next)) {
      debugPrint('[NotificationService] skip — same nextReview, already handled');
      return true;
    }

    return scheduleReminderAt(next, force: force);
  }

  Future<bool> _shouldSkipReschedule(DateTime nextReview) async {
    final prefs = await SharedPreferences.getInstance();
    final int sourceMillis = nextReview.millisecondsSinceEpoch;
    final int? lastSource = prefs.getInt(_prefLastSourceNextReviewMillis);

    if (lastSource != sourceMillis) return false;

    if (await _hasPendingStudyReminder()) return true;

    final int? handledDue = prefs.getInt(_prefHandledDueSourceMillis);
    if (handledDue == sourceMillis) return true;

    final int? lastFire = prefs.getInt(_prefLastReminderMillis);
    if (lastFire != null) {
      final DateTime fireAt = DateTime.fromMillisecondsSinceEpoch(lastFire);
      if (fireAt.isAfter(DateTime.now())) return true;
    }

    return false;
  }

  Future<bool> _hasPendingStudyReminder() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.any((p) => p.id == _reminderNotificationId);
  }

  /// Hẹn đúng [at] — gọi ngay sau khi đánh dấu flashcard (tránh đọc Firestore chậm).
  Future<bool> scheduleReminderAt(DateTime at, {bool force = false}) async {
    await init();

    if (!await _isNotificationsEnabled()) {
      debugPrint('[NotificationService] notifications disabled');
      return false;
    }

    if (!await requestNotificationPermission()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final DateTime? fireAt = await _resolveFireTime(at, prefs);
    if (fireAt == null) {
      debugPrint('[NotificationService] skip — due reminder already sent');
      return false;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(fireAt, tz.local);
    debugPrint('[NotificationService] vocabulary reminder at $scheduledDate');

    if (!force && await _isStudyReminderAlreadyScheduled(scheduledDate)) {
      return true;
    }

    final ok = await _scheduleReminder(
      scheduledDate,
      title: 'Time to Study!',
      body: 'You have new words ready for review!',
      notificationId: _reminderNotificationId,
    );

    if (ok) {
      await prefs.setInt(_prefLastReminderMillis, scheduledDate.millisecondsSinceEpoch);
      await prefs.setInt(_prefLastSourceNextReviewMillis, at.millisecondsSinceEpoch);
      _lastScheduledFireAt = fireAt;
    }
    return ok;
  }

  Future<DateTime?> _resolveFireTime(
    DateTime nextReview,
    SharedPreferences prefs,
  ) async {
    final DateTime now = DateTime.now();
    final int sourceMillis = nextReview.millisecondsSinceEpoch;

    if (nextReview.isAfter(now)) {
      await prefs.remove(_prefDueReminderMillis);
      await prefs.remove(_prefHandledDueSourceMillis);
      return nextReview;
    }

    final int? handledDue = prefs.getInt(_prefHandledDueSourceMillis);
    if (handledDue == sourceMillis) return null;

    final int? saved = prefs.getInt(_prefDueReminderMillis);
    if (saved != null) {
      final DateTime fireAt = DateTime.fromMillisecondsSinceEpoch(saved);
      if (fireAt.isAfter(now)) return fireAt;
      await prefs.setInt(_prefHandledDueSourceMillis, sourceMillis);
      await prefs.remove(_prefDueReminderMillis);
      return null;
    }

    final DateTime fireAt = now.add(const Duration(minutes: 1));
    await prefs.setInt(_prefDueReminderMillis, fireAt.millisecondsSinceEpoch);
    return fireAt;
  }

  Future<bool> _isStudyReminderAlreadyScheduled(tz.TZDateTime target) async {
    if (!await _hasPendingStudyReminder()) return false;

    final prefs = await SharedPreferences.getInstance();
    final int? lastMillis = prefs.getInt(_prefLastReminderMillis);
    if (lastMillis == null) return false;

    final tz.TZDateTime last = tz.TZDateTime.from(
      DateTime.fromMillisecondsSinceEpoch(lastMillis),
      tz.local,
    );
    return (target.difference(last).inSeconds).abs() < 60;
  }

  Future<bool> _scheduleReminder(
    tz.TZDateTime scheduledDate, {
    required String title,
    required String body,
    required int notificationId,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(now)) {
      debugPrint('[NotificationService] skip past: $scheduledDate');
      return false;
    }

    final pending = await _notificationsPlugin.pendingNotificationRequests();
    if (pending.any((p) => p.id == notificationId)) {
      await _notificationsPlugin.cancel(id: notificationId);
    }

    final modes = Platform.isAndroid
        ? [
            AndroidScheduleMode.exactAllowWhileIdle,
            AndroidScheduleMode.inexactAllowWhileIdle,
            AndroidScheduleMode.exact,
          ]
        : [AndroidScheduleMode.exactAllowWhileIdle];

    for (final mode in modes) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: _notificationDetails,
          androidScheduleMode: mode,
        );
        debugPrint('[NotificationService] scheduled id=$notificationId mode=$mode');
        return true;
      } catch (e) {
        debugPrint('[NotificationService] schedule failed mode=$mode: $e');
      }
    }
    return false;
  }

  Future<bool> showTestNotificationNow() async {
    await init();
    if (!await requestNotificationPermission()) return false;
    try {
      await _notificationsPlugin.show(
        id: _testNotificationId,
        title: 'Time to Study!',
        body: 'Test — bạn có thể vuốt xóa thông báo này.',
        notificationDetails: _notificationDetails,
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] show test failed: $e');
      return false;
    }
  }

  Future<bool> scheduleTestNotification({int seconds = 10}) async {
    await init();
    if (!await requestNotificationPermission()) return false;
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    return _scheduleReminder(
      when,
      title: 'Time to Study!',
      body: 'Test hẹn giờ — vuốt xóa được sau khi hiện.',
      notificationId: _testNotificationId,
    );
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefLastReminderMillis);
    await prefs.remove(_prefDueReminderMillis);
    await prefs.remove(_prefLastSourceNextReviewMillis);
    await prefs.remove(_prefHandledDueSourceMillis);
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }
}
