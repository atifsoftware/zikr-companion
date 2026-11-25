import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AyahItem {
  final int numberInSurah;
  final String arabic;
  final String banglaTranslation;
  final String banglaTafsir;
  final String transliteration;
  final String audioUrl;
  final String? localAudioPath;

  const AyahItem({
    required this.numberInSurah,
    required this.arabic,
    required this.banglaTranslation,
    required this.banglaTafsir,
    required this.transliteration,
    required this.audioUrl,
    this.localAudioPath,
  });

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'arabic': arabic,
        'banglaTranslation': banglaTranslation,
        'banglaTafsir': banglaTafsir,
        'transliteration': transliteration,
        'audioUrl': audioUrl,
      };

  factory AyahItem.fromJson(
    Map<String, dynamic> json, {
    String? localAudioPath,
  }) =>
      AyahItem(
        numberInSurah: json['numberInSurah'] as int,
        arabic: json['arabic'] as String,
        banglaTranslation: json['banglaTranslation'] as String,
        banglaTafsir: (json['banglaTafsir'] as String?) ?? '',
        transliteration: (json['transliteration'] as String?) ?? '',
        audioUrl: (json['audioUrl'] as String?) ?? '',
        localAudioPath: localAudioPath,
      );
}

class QuranTextService {
  final Map<String, List<AyahItem>> _cache = {};

  String _cacheKey(String qariId, int surahNumber) => '${qariId}_$surahNumber';

  Future<Directory> _surahDir(String qariId, int surahNumber) async {
    final base = await getApplicationSupportDirectory();
    final safeQari = qariId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return Directory(
      '${base.path}${Platform.pathSeparator}quran_offline${Platform.pathSeparator}${safeQari}_$surahNumber',
    );
  }

  Future<bool> isSurahDownloaded(String qariId, int surahNumber) async {
    try {
      final dir = await _surahDir(qariId, surahNumber);
      final marker = File('${dir.path}${Platform.pathSeparator}.complete');
      final jsonFile = File('${dir.path}${Platform.pathSeparator}ayahs.json');
      return await marker.exists() && await jsonFile.exists();
    } catch (_) {
      return false;
    }
  }

  Future<List<AyahItem>> fetchSurahAyahs(
    int surahNumber, {
    String qariId = 'ar.alafasy',
  }) async {
    final key = _cacheKey(qariId, surahNumber);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Check offline cache first.
    try {
      final dir = await _surahDir(qariId, surahNumber);
      final jsonFile = File('${dir.path}${Platform.pathSeparator}ayahs.json');
      if (await jsonFile.exists()) {
        final raw = await jsonFile.readAsString();
        final decoded = jsonDecode(raw) as List<dynamic>;
        final offlineItems = <AyahItem>[];
        for (final entry in decoded) {
          final map = entry as Map<String, dynamic>;
          final num = map['numberInSurah'] as int;
          final mp3File = File('${dir.path}${Platform.pathSeparator}$num.mp3');
          final localPath = await mp3File.exists() ? mp3File.path : null;
          offlineItems.add(AyahItem.fromJson(map, localAudioPath: localPath));
        }
        _cache[key] = offlineItems;
        return offlineItems;
      }
    } catch (_) {}

    final uri = Uri.parse(
      'https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,bn.bengali,bn.hoque,$qariId',
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 15),
          );
      final response = await request.close().timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final editions = decoded['data'] as List<dynamic>;

      final arabicAyahs =
          (editions[0]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
      final banglaAyahs =
          (editions[1]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
      final tafsirAyahs =
          (editions[2]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
      final audioAyahs =
          (editions[3]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();

      final items = List.generate(arabicAyahs.length, (i) {
        final arabicText = (arabicAyahs[i]['text'] as String).trim();
        return AyahItem(
          numberInSurah: arabicAyahs[i]['numberInSurah'] as int,
          arabic: arabicText,
          banglaTranslation: (banglaAyahs[i]['text'] as String).trim(),
          banglaTafsir: (tafsirAyahs[i]['text'] as String).trim(),
          transliteration: '',
          audioUrl: (audioAyahs[i]['audio'] as String? ?? '').trim(),
        );
      });

      _cache[key] = items;
      return items;
    } finally {
      client.close();
    }
  }

  Future<void> downloadSurahForOffline(
    int surahNumber, {
    String qariId = 'ar.alafasy',
    void Function(int done, int total)? onProgress,
  }) async {
    final key = _cacheKey(qariId, surahNumber);
    _cache.remove(key);
    final items = await fetchSurahAyahs(surahNumber, qariId: qariId);
    final dir = await _surahDir(qariId, surahNumber);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final client = HttpClient();
    final updatedItems = <AyahItem>[];
    try {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        onProgress?.call(i, items.length);
        final mp3File =
            File('${dir.path}${Platform.pathSeparator}${item.numberInSurah}.mp3');

        if (!await mp3File.exists() && item.audioUrl.isNotEmpty) {
          final req = await client
              .getUrl(Uri.parse(item.audioUrl))
              .timeout(const Duration(seconds: 20));
          final res = await req.close().timeout(const Duration(seconds: 20));
          if (res.statusCode == 200) {
            final bytes = await res.fold<List<int>>(
              <int>[],
              (prev, chunk) => prev..addAll(chunk),
            );
            await mp3File.writeAsBytes(bytes);
          }
        }

        updatedItems.add(
          AyahItem(
            numberInSurah: item.numberInSurah,
            arabic: item.arabic,
            banglaTranslation: item.banglaTranslation,
            banglaTafsir: item.banglaTafsir,
            transliteration: item.transliteration,
            audioUrl: item.audioUrl,
            localAudioPath: await mp3File.exists() ? mp3File.path : null,
          ),
        );
      }

      final jsonFile = File('${dir.path}${Platform.pathSeparator}ayahs.json');
      await jsonFile.writeAsString(
        jsonEncode(updatedItems.map((e) => e.toJson()).toList()),
      );
      final marker = File('${dir.path}${Platform.pathSeparator}.complete');
      await marker.writeAsString('ok');

      _cache[key] = updatedItems;
      onProgress?.call(items.length, items.length);
    } finally {
      client.close();
    }
  }
}
