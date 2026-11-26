import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_inspiration.dart';
import '../models/zikr_item.dart';
import '../screens/dua_screen.dart';
import '../utils/http_fetch.dart';
import '../utils/io_compat.dart';

class RemoteNotification {
  final int id;
  final String title;
  final String body;
  final String createdAt;

  const RemoteNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory RemoteNotification.fromJson(Map<String, dynamic> json) =>
      RemoteNotification(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        createdAt: (json['created_at'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'created_at': createdAt,
      };
}

class RemoteSyncResult {
  final List<ZikrItem> zikrs;
  final List<DailyInspiration> inspirations;
  final List<DuaItem> duas;
  final List<RemoteNotification> notifications;

  const RemoteSyncResult({
    required this.zikrs,
    required this.inspirations,
    required this.duas,
    required this.notifications,
  });
}

class RemoteSyncService {
  Uri _buildSyncUri(String baseUrl) {
    var clean = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) {
      throw Exception('Invalid URL');
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }
    final lower = clean.toLowerCase();
    if (lower.endsWith('/api/sync.php') ||
        lower.endsWith('/api/sync') ||
        lower.endsWith('/api/v1/sync')) {
      return Uri.parse(clean);
    }
    return Uri.parse('$clean/api/sync.php');
  }

  Future<List<ZikrItem>> fetchAndCacheZikrs(String baseUrl) async {
    final result = await fetchAll(baseUrl);
    return result.zikrs;
  }

  Future<RemoteSyncResult> fetchAll(String baseUrl, {String? deviceId}) async {
    final baseUri = _buildSyncUri(baseUrl);
    final platform = kIsWeb
        ? 'web'
        : ((Platform.isAndroid || Platform.isIOS) ? 'mobile' : 'desktop');

    final params = Map<String, String>.from(baseUri.queryParameters);
    params['platform'] = platform;
    if (deviceId != null && deviceId.isNotEmpty) {
      params['device_id'] = deviceId;
    }
    final uri = baseUri.replace(queryParameters: params);

    final body = await fetchTextUrl(
      uri.toString(),
      headers: kIsWeb ? const {} : {'X-App-Platform': platform},
    );
    final decoded = jsonDecode(body) as Map<String, dynamic>;

    final rawList = (decoded['zikrs'] as List<dynamic>?) ??
        (decoded['zikr_items'] as List<dynamic>?) ??
        [];

    Directory? audioDir;
    if (!kIsWeb) {
      final baseDir = await getApplicationSupportDirectory();
      audioDir = Directory(
        '${baseDir.path}${Platform.pathSeparator}remote_audio',
      );
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
    }

    final items = <ZikrItem>[];
    for (final raw in rawList) {
      final map = raw as Map<String, dynamic>;
      final id = map['id'].toString();
      final audioUrl =
          (map['audioUrl'] as String?) ?? (map['audio_url'] as String?) ?? '';
      String localAudioPath = '';

      if (kIsWeb && audioUrl.isNotEmpty) {
        localAudioPath = audioUrl;
      } else if (!kIsWeb && audioDir != null && audioUrl.isNotEmpty) {
        final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final ext = audioUrl.split('.').last.split('?').first;
        final fileExt =
            ['mp3', 'wav', 'm4a', 'aac'].contains(ext.toLowerCase())
                ? ext.toLowerCase()
                : 'mp3';
        final targetFile = File(
          '${audioDir.path}${Platform.pathSeparator}$safeId.$fileExt',
        );
        if (!await targetFile.exists()) {
          final bytes = await fetchBytesUrl(audioUrl);
          if (bytes != null && bytes.isNotEmpty) {
            await targetFile.writeAsBytes(bytes);
          }
        }
        if (await targetFile.exists()) {
          localAudioPath = targetFile.path;
        }
      }

      items.add(
        ZikrItem(
          id: id,
          arabic: (map['arabic'] as String?) ?? '',
          banglaPronunciation: (map['banglaPronunciation'] as String?) ??
              (map['bangla_pronunciation'] as String?) ??
              '',
          englishPhonetic: (map['englishPhonetic'] as String?) ??
              (map['english_phonetic'] as String?) ??
              '',
          banglaMeaning: (map['banglaMeaning'] as String?) ??
              (map['bangla_meaning'] as String?) ??
              '',
          virtue: (map['virtue'] as String?) ?? '',
          customAudioPath: localAudioPath,
          repeatCount: (map['repeatCount'] as num?)?.toInt() ??
              (map['repeat_count'] as num?)?.toInt(),
          isEnabled: true,
          isCustom: false,
        ),
      );
    }

    final rawInspirations = (decoded['inspirations'] as List<dynamic>?) ?? [];
    final inspirations = rawInspirations
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

    final rawDuas = (decoded['duas'] as List<dynamic>?) ?? [];
    final duas = rawDuas
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => DuaItem(
            category: (m['category'] as String?) ?? 'মাসনুন দোয়া',
            title: (m['title'] as String?) ?? '',
            arabic: (m['arabic'] as String?) ?? '',
            banglaPronunciation:
                (m['bangla_pronunciation'] as String?) ?? '',
            banglaMeaning: (m['bangla_meaning'] as String?) ?? '',
            reference: (m['reference'] as String?) ?? '',
            audioUrl: (m['audio_url'] as String?) ?? '',
          ),
        )
        .where((e) => e.title.isNotEmpty && e.arabic.isNotEmpty)
        .toList();

    final rawNotifs = (decoded['notifications'] as List<dynamic>?) ?? [];
    final notifications = rawNotifs
        .whereType<Map<String, dynamic>>()
        .map(RemoteNotification.fromJson)
        .where((n) => n.id > 0 && n.title.isNotEmpty)
        .toList();

    return RemoteSyncResult(
      zikrs: items,
      inspirations: inspirations,
      duas: duas,
      notifications: notifications,
    );
  }
}
