import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/daily_inspiration.dart';
import '../models/zikr_item.dart';
import '../screens/dua_screen.dart';

class StorageService {
  static const _settingsKey = 'zikr_app_settings';
  static const _zikrListKey = 'zikr_items_list';
  static const _dailyHistoryKey = 'zikr_daily_history';
  static const _remoteInspirationsKey = 'zikr_remote_inspirations';
  static const _remoteDuasKey = 'zikr_remote_duas';
  static const _lastNotifIdKey = 'zikr_last_remote_notif_id';
  static const _deviceIdKey = 'zikr_device_unique_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  List<ZikrItem> loadZikrList() {
    final raw = _prefs.getString(_zikrListKey);
    if (raw == null) return ZikrItem.defaultList();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((e) => ZikrItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) return ZikrItem.defaultList();
      final idx = list.indexWhere((e) => e.id == ZikrItem.masudFourZikr.id);
      if (idx == -1) {
        return [ZikrItem.masudFourZikr, ...list];
      }
      final existing = list[idx];
      final updated = ZikrItem.masudFourZikr.copyWith(isEnabled: existing.isEnabled);
      final others = list.where((e) => e.id != ZikrItem.masudFourZikr.id);
      return [updated, ...others];
    } catch (_) {
      return ZikrItem.defaultList();
    }
  }

  Future<void> saveZikrList(List<ZikrItem> items) async {
    await _prefs.setString(
      _zikrListKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Map<String, int> loadDailyHistory() {
    final raw = _prefs.getString(_dailyHistoryKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  int loadTodayCount() {
    final history = loadDailyHistory();
    return history[dateKey(DateTime.now())] ?? 0;
  }

  Future<void> saveTodayCount(int count) async {
    final history = loadDailyHistory();
    history[dateKey(DateTime.now())] = count;
    // Keep only the most recent 60 days.
    if (history.length > 60) {
      final sortedKeys = history.keys.toList()..sort();
      for (final oldKey in sortedKeys.take(history.length - 60)) {
        history.remove(oldKey);
      }
    }
    await _prefs.setString(_dailyHistoryKey, jsonEncode(history));
  }

  static String dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  List<DailyInspiration> loadRemoteInspirations() {
    final raw = _prefs.getString(_remoteInspirationsKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => DailyInspiration(
              arabic: (m['arabic'] as String?) ?? '',
              bangla: (m['bangla'] as String?) ?? '',
              reference: (m['reference'] as String?) ?? '',
            ),
          )
          .where((e) => e.bangla.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRemoteInspirations(List<DailyInspiration> list) async {
    await _prefs.setString(
      _remoteInspirationsKey,
      jsonEncode(
        list
            .map(
              (e) => {
                'arabic': e.arabic,
                'bangla': e.bangla,
                'reference': e.reference,
              },
            )
            .toList(),
      ),
    );
  }

  List<DuaItem> loadRemoteDuas() {
    final raw = _prefs.getString(_remoteDuasKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => DuaItem(
              category: (m['category'] as String?) ?? 'মাসনুন দোয়া',
              title: (m['title'] as String?) ?? '',
              arabic: (m['arabic'] as String?) ?? '',
              banglaPronunciation: (m['bangla_pronunciation'] as String?) ?? '',
              banglaMeaning: (m['bangla_meaning'] as String?) ?? '',
              reference: (m['reference'] as String?) ?? '',
              audioUrl: (m['audio_url'] as String?) ?? '',
            ),
          )
          .where((e) => e.title.isNotEmpty && e.arabic.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRemoteDuas(List<DuaItem> list) async {
    await _prefs.setString(
      _remoteDuasKey,
      jsonEncode(
        list
            .map(
              (e) => {
                'category': e.category,
                'title': e.title,
                'arabic': e.arabic,
                'bangla_pronunciation': e.banglaPronunciation,
                'bangla_meaning': e.banglaMeaning,
                'reference': e.reference,
                'audio_url': e.audioUrl,
              },
            )
            .toList(),
      ),
    );
  }

  int loadLastNotificationId() => _prefs.getInt(_lastNotifIdKey) ?? 0;

  Future<void> saveLastNotificationId(int id) async {
    await _prefs.setInt(_lastNotifIdKey, id);
  }

  Future<String> getOrCreateDeviceId() async {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated =
        'zk_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await _prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  String exportBackupJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': loadSettings().toJson(),
      'zikrList': loadZikrList().map((e) => e.toJson()).toList(),
      'history': loadDailyHistory(),
    });
  }

  Future<bool> importBackupJson(String raw) async {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['settings'] is Map<String, dynamic>) {
        final s = AppSettings.fromJson(
          decoded['settings'] as Map<String, dynamic>,
        );
        await saveSettings(s);
      }
      if (decoded['zikrList'] is List<dynamic>) {
        final list = (decoded['zikrList'] as List<dynamic>)
            .map((e) => ZikrItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          await saveZikrList(list);
        }
      }
      if (decoded['history'] is Map<String, dynamic>) {
        final hist = (decoded['history'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt()));
        await _prefs.setString(_dailyHistoryKey, jsonEncode(hist));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
