import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/zikr_item.dart';

class RemoteSyncService {
  Future<List<ZikrItem>> fetchAndCacheZikrs(String baseUrl) async {
    final clean = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) {
      throw Exception('Invalid URL');
    }

    final uri = Uri.parse('$clean/api/sync.php');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final rawList = (decoded['zikrs'] as List<dynamic>?) ?? [];

      final baseDir = await getApplicationSupportDirectory();
      final audioDir = Directory(
        '${baseDir.path}${Platform.pathSeparator}remote_audio',
      );
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final items = <ZikrItem>[];
      for (final raw in rawList) {
        final map = raw as Map<String, dynamic>;
        final id = map['id'] as String;
        final audioUrl = (map['audioUrl'] as String?) ?? '';
        String localAudioPath = '';

        if (audioUrl.isNotEmpty) {
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
            try {
              final audioReq = await client
                  .getUrl(Uri.parse(audioUrl))
                  .timeout(const Duration(seconds: 25));
              final audioRes =
                  await audioReq.close().timeout(const Duration(seconds: 25));
              if (audioRes.statusCode == 200) {
                final bytes = await audioRes.fold<List<int>>(
                  <int>[],
                  (prev, chunk) => prev..addAll(chunk),
                );
                await targetFile.writeAsBytes(bytes);
              }
            } catch (_) {}
          }
          if (await targetFile.exists()) {
            localAudioPath = targetFile.path;
          }
        }

        items.add(
          ZikrItem(
            id: id,
            arabic: (map['arabic'] as String?) ?? '',
            banglaPronunciation: (map['banglaPronunciation'] as String?) ?? '',
            englishPhonetic: (map['englishPhonetic'] as String?) ?? '',
            banglaMeaning: (map['banglaMeaning'] as String?) ?? '',
            virtue: (map['virtue'] as String?) ?? '',
            customAudioPath: localAudioPath,
            repeatCount: map['repeatCount'] as int?,
            isEnabled: true,
            isCustom: false,
          ),
        );
      }
      return items;
    } finally {
      client.close();
    }
  }
}
