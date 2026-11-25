import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_settings.dart';
import '../models/zikr_item.dart';
import 'desktop_tray_service.dart';
import 'hijri_service.dart';
import 'prayer_service.dart';
import 'storage_service.dart';
import 'zikr_voice_service.dart';

class DailyZikrStat {
  final DateTime date;
  final int count;

  const DailyZikrStat(this.date, this.count);
}

class ZikrSchedulerService extends ChangeNotifier {
  final StorageService _storage;
  final PrayerService _prayerService = PrayerService();
  final HijriService _hijriService = HijriService();
  final ZikrVoiceService _voiceService = ZikrVoiceService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  AppSettings _settings;
  List<ZikrItem> _zikrList;
  int _todayCount;
  Map<String, int> _history;
  int _currentIndex = 0;

  Timer? _tickTimer;
  DateTime? _nextTriggerAt;
  ZikrItem? _activeReminder;
  ZikrItem? _currentZikr;
  int _reminderProgress = 0;
  bool _notificationsInitialized = false;
  String? _lastPreAlertKey;
  String? _lastAzanAlertKey;

  void Function(ZikrItem item, int repeatCount)? onReminderTriggered;
  VoidCallback? onReminderAutoClose;
  void Function(PrayerSlot prayer, int minutesLeft)? onPrePrayerAlert;
  void Function(PrayerSlot prayer)? onAzanAlert;

  ZikrSchedulerService(this._storage)
      : _settings = _storage.loadSettings(),
        _zikrList = _storage.loadZikrList(),
        _history = _storage.loadDailyHistory(),
        _todayCount = _storage.loadTodayCount() {
    _initNotifications();
    _rescheduleNext();
    _startTicker();
  }

  AppSettings get settings => _settings;
  List<ZikrItem> get zikrList => List.unmodifiable(_zikrList);
  int get todayCount => _todayCount;
  ZikrItem? get activeReminder => _activeReminder;
  ZikrItem? get currentZikr => _currentZikr;
  int get reminderProgress => _reminderProgress;
  HijriDateInfo get hijriDate => _hijriService.fromGregorian(DateTime.now());
  List<String> get todayIslamicReminders =>
      _hijriService.getTodayIslamicReminders(DateTime.now());
  bool get isQuietHours => _settings.isWithinQuietHours(DateTime.now());

  List<ZikrItem> get enabledZikrList =>
      _zikrList.where((z) => z.isEnabled).toList();

  int effectiveRepeatFor(ZikrItem item) =>
      item.repeatCount ?? _settings.repeatCount;

  List<DailyZikrStat> get last7DaysStats {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final key = StorageService.dateKey(day);
      final count = key == StorageService.dateKey(now)
          ? _todayCount
          : (_history[key] ?? 0);
      return DailyZikrStat(day, count);
    });
  }

  int get currentStreak {
    final now = DateTime.now();
    int streak = 0;
    for (int offset = 0; offset < 60; offset++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: offset));
      final key = StorageService.dateKey(day);
      final count = offset == 0 ? _todayCount : (_history[key] ?? 0);
      if (count > 0) {
        streak++;
      } else if (offset > 0) {
        break;
      }
    }
    return streak;
  }

  PrayerPauseStatus get currentPrayerPause => _prayerService.checkPrayerPause(
        latitude: _settings.latitude,
        longitude: _settings.longitude,
        autoPauseEnabled: _settings.autoPauseOnPrayer,
        pauseMinutes: _settings.prayerPauseMinutes,
        useCustomTimes: _settings.useCustomPrayerTimes,
        customTimes: _settings.customPrayerTimes,
      );

  List<PrayerSlot> get todayPrayerTimes => _prayerService.getPrayerTimesForDate(
        latitude: _settings.latitude,
        longitude: _settings.longitude,
        useCustomTimes: _settings.useCustomPrayerTimes,
        customTimes: _settings.customPrayerTimes,
      );

  PrayerSlot get nextPrayer => _prayerService.getNextPrayer(
        latitude: _settings.latitude,
        longitude: _settings.longitude,
        useCustomTimes: _settings.useCustomPrayerTimes,
        customTimes: _settings.customPrayerTimes,
      );

  ({DateTime sehriEnd, DateTime iftarTime}) get todaySehriIftar =>
      _prayerService.getSehriAndIftarTimes(
        latitude: _settings.latitude,
        longitude: _settings.longitude,
        useCustomTimes: _settings.useCustomPrayerTimes,
        customTimes: _settings.customPrayerTimes,
      );

  Duration get timeUntilNextReminder {
    if (!_settings.isReminderActive || _nextTriggerAt == null) {
      return Duration.zero;
    }
    final diff = _nextTriggerAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _initNotifications() async {
    if (kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings();
      const linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open Zikr');
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );
      await _notifications.initialize(initSettings);
      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      _notificationsInitialized = true;
      await _scheduleBackgroundReminders();
    } catch (_) {
      _notificationsInitialized = false;
    }
  }

  Future<void> _scheduleBackgroundReminders() async {
    if (!_notificationsInitialized || kIsWeb || Platform.isWindows) return;
    try {
      await _notifications.cancelAll();
      if (!_settings.isReminderActive) return;

      final enabled = enabledZikrList;
      if (enabled.isEmpty) return;

      final now = DateTime.now();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'zikr_reminder_channel',
          'জিকির রিমাইন্ডার',
          channelDescription: 'নির্দিষ্ট সময় পর পর আল্লাহর জিকির মনে করিয়ে দেয়',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      for (var i = 1; i <= 12; i++) {
        final target = now.add(Duration(minutes: _settings.intervalMinutes * i));
        if (_settings.isWithinQuietHours(target)) continue;
        final pause = _prayerService.checkPrayerPause(
          latitude: _settings.latitude,
          longitude: _settings.longitude,
          autoPauseEnabled: _settings.autoPauseOnPrayer,
          pauseMinutes: _settings.prayerPauseMinutes,
          now: target,
          useCustomTimes: _settings.useCustomPrayerTimes,
          customTimes: _settings.customPrayerTimes,
        );
        if (pause.isPaused) continue;

        final item = enabled[(i - 1) % enabled.length];
        final repeat = effectiveRepeatFor(item);
        await _notifications.zonedSchedule(
          2000 + i,
          '${item.banglaPronunciation} ($repeat বার)',
          '${item.arabic} — ${item.banglaMeaning}',
          tz.TZDateTime.from(target, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_settings.isReminderActive) return;

      _checkPrePrayerAlert();
      _checkAzanAlert();

      if (_settings.isWithinQuietHours(DateTime.now())) {
        notifyListeners();
        return;
      }

      final pauseStatus = currentPrayerPause;
      if (pauseStatus.isPaused) {
        notifyListeners();
        return;
      }

      if (_nextTriggerAt != null && !DateTime.now().isBefore(_nextTriggerAt!)) {
        triggerZikrNow();
      } else {
        notifyListeners();
      }
    });
  }

  void _checkPrePrayerAlert() {
    if (!_settings.prePrayerAlertEnabled ||
        _settings.prePrayerAlertMinutes <= 0) {
      return;
    }
    final now = DateTime.now();
    final upcoming = nextPrayer;
    final diff = upcoming.startTime.difference(now);
    final alertWindow = Duration(minutes: _settings.prePrayerAlertMinutes);

    if (diff > Duration.zero && diff <= alertWindow) {
      final key =
          '${StorageService.dateKey(upcoming.startTime)}_${upcoming.nameEnglish}';
      if (_lastPreAlertKey != key) {
        _lastPreAlertKey = key;
        onPrePrayerAlert?.call(upcoming, diff.inMinutes + 1);
      }
    }
  }

  void _checkAzanAlert() {
    if (!_settings.azanAlertEnabled) return;
    final now = DateTime.now();
    for (final slot in todayPrayerTimes) {
      final diff = now.difference(slot.startTime);
      if (diff >= Duration.zero && diff <= const Duration(minutes: 2)) {
        final key =
            '${StorageService.dateKey(slot.startTime)}_${slot.nameEnglish}';
        if (_lastAzanAlertKey != key) {
          _lastAzanAlertKey = key;
          onAzanAlert?.call(slot);
          _showAzanNotification(slot);
        }
      }
    }
  }

  Future<void> _showAzanNotification(PrayerSlot slot) async {
    if (!_notificationsInitialized || kIsWeb || Platform.isWindows) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'zikr_azan_channel',
          'নামাজের ওয়াক্ত সতর্কতা',
          channelDescription: 'নামাজের ওয়াক্ত শুরু হলে মনে করিয়ে দেয়',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _notifications.show(
        1002,
        'আল্লাহু আকবার — ${slot.nameBangla} ওয়াক্ত',
        '${slot.nameBangla} নামাজের ওয়াক্ত শুরু হয়েছে।',
        details,
      );
    } catch (_) {}
  }

  void _rescheduleNext() {
    _nextTriggerAt =
        DateTime.now().add(Duration(minutes: _settings.intervalMinutes));
  }

  void triggerZikrNow({bool ignorePrayerPause = false}) {
    final enabled = enabledZikrList;
    if (enabled.isEmpty) return;

    if (!ignorePrayerPause &&
        (currentPrayerPause.isPaused ||
            _settings.isWithinQuietHours(DateTime.now()))) {
      _rescheduleNext();
      notifyListeners();
      return;
    }

    if (_currentIndex >= enabled.length) {
      _currentIndex = 0;
    }
    final item = enabled[_currentIndex];
    _currentIndex = (_currentIndex + 1) % enabled.length;

    final targetRepeat = effectiveRepeatFor(item);
    _activeReminder = item;
    _currentZikr = item;
    _reminderProgress = 0;
    _rescheduleNext();
    _showSystemNotification(item, targetRepeat);
    if (_settings.voiceEnabled) {
      _voiceService.speakZikr(
        item,
        repeatCount: targetRepeat,
        speechRate: _settings.speechRate,
        onRepetitionDone: (completed) {
          _reminderProgress = completed;
          incrementTodayCount(1);
        },
        onCompleted: () {
          Future.delayed(const Duration(milliseconds: 500), () {
            onReminderAutoClose?.call();
          });
        },
      );
    }
    if (_settings.showReminderPopup) {
      onReminderTriggered?.call(item, targetRepeat);
    }
    notifyListeners();
  }

  Future<void> testVoice() async {
    final enabled = enabledZikrList;
    final item = enabled.isNotEmpty ? enabled.first : _zikrList.first;
    await _voiceService.speakZikr(
      item,
      repeatCount: 1,
      speechRate: _settings.speechRate,
    );
  }

  Future<void> playZikrItem(ZikrItem item) async {
    _currentZikr = item;
    final enabled = enabledZikrList;
    final idx = enabled.indexWhere((e) => e.id == item.id);
    if (idx != -1 && enabled.isNotEmpty) {
      _currentIndex = (idx + 1) % enabled.length;
    }
    notifyListeners();
    await _voiceService.speakZikr(
      item,
      repeatCount: 1,
      speechRate: _settings.speechRate,
    );
  }

  Future<void> stopVoice() async {
    await _voiceService.stop();
  }

  Future<void> _showSystemNotification(ZikrItem item, int repeat) async {
    if (!_notificationsInitialized || kIsWeb) return;
    if (Platform.isWindows) return;

    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'zikr_reminder_channel',
          'জিকির রিমাইন্ডার',
          channelDescription: 'নির্দিষ্ট সময় পর পর আল্লাহর জিকির মনে করিয়ে দেয়',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );
      await _notifications.show(
        1001,
        '${item.banglaPronunciation} ($repeat বার)',
        '${item.arabic} — ${item.banglaMeaning}',
        details,
      );
    } catch (_) {}
  }

  void clearActiveReminder() {
    _activeReminder = null;
    notifyListeners();
  }

  Future<void> incrementTodayCount([int amount = 1]) async {
    _todayCount += amount;
    _history[StorageService.dateKey(DateTime.now())] = _todayCount;
    await _storage.saveTodayCount(_todayCount);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    final intervalChanged =
        newSettings.intervalMinutes != _settings.intervalMinutes;
    final startupChanged =
        newSettings.launchAtStartup != _settings.launchAtStartup;

    _settings = newSettings;
    await _storage.saveSettings(_settings);

    if (intervalChanged || _settings.isReminderActive) {
      _rescheduleNext();
    }
    if (startupChanged) {
      await DesktopTrayService.setLaunchAtStartup(_settings.launchAtStartup);
    }
    await _scheduleBackgroundReminders();
    notifyListeners();
  }

  String exportBackupJson() => _storage.exportBackupJson();

  Future<bool> importBackupJson(String raw) async {
    final ok = await _storage.importBackupJson(raw);
    if (!ok) return false;
    _settings = _storage.loadSettings();
    _zikrList = _storage.loadZikrList();
    _history = _storage.loadDailyHistory();
    _todayCount = _storage.loadTodayCount();
    _rescheduleNext();
    await _scheduleBackgroundReminders();
    notifyListeners();
    return true;
  }

  Future<void> toggleReminderActive() async {
    await updateSettings(
      _settings.copyWith(isReminderActive: !_settings.isReminderActive),
    );
  }

  Future<void> toggleZikrEnabled(String id) async {
    _zikrList = _zikrList
        .map((item) =>
            item.id == id ? item.copyWith(isEnabled: !item.isEnabled) : item)
        .toList();
    await _storage.saveZikrList(_zikrList);
    await _scheduleBackgroundReminders();
    notifyListeners();
  }

  Future<void> updateZikrRepeatCount(String id, int? repeatCount) async {
    _zikrList = _zikrList
        .map((item) => item.id == id
            ? (repeatCount == null
                ? item.copyWith(clearRepeatCount: true)
                : item.copyWith(repeatCount: repeatCount))
            : item)
        .toList();
    await _storage.saveZikrList(_zikrList);
    await _scheduleBackgroundReminders();
    notifyListeners();
  }

  Future<void> addCustomZikr({
    required String arabic,
    required String banglaPronunciation,
    required String banglaMeaning,
    String virtue = '',
    String customAudioPath = '',
  }) async {
    final item = ZikrItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      arabic: arabic.trim(),
      banglaPronunciation: banglaPronunciation.trim(),
      banglaMeaning: banglaMeaning.trim(),
      virtue: virtue.trim(),
      customAudioPath: customAudioPath.trim(),
      isEnabled: true,
      isCustom: true,
    );
    _zikrList = [..._zikrList, item];
    await _storage.saveZikrList(_zikrList);
    notifyListeners();
  }

  Future<void> deleteCustomZikr(String id) async {
    _zikrList = _zikrList.where((item) => item.id != id).toList();
    await _storage.saveZikrList(_zikrList);
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
