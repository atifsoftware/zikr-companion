import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/http_fetch.dart';
import '../utils/io_compat.dart';

class AyahWord {
  final String ar;
  final String bn;

  const AyahWord({required this.ar, required this.bn});

  Map<String, dynamic> toJson() => {'ar': ar, 'bn': bn};

  factory AyahWord.fromJson(Map<String, dynamic> json) => AyahWord(
        ar: (json['ar'] as String?) ?? '',
        bn: (json['bn'] as String?) ?? '',
      );
}

class WordSegment {
  final int wordIndex; // 0-based index into AyahItem.words
  final int startMs;
  final int endMs;

  const WordSegment({
    required this.wordIndex,
    required this.startMs,
    required this.endMs,
  });

  Map<String, dynamic> toJson() =>
      {'w': wordIndex, 's': startMs, 'e': endMs};

  factory WordSegment.fromJson(Map<String, dynamic> json) => WordSegment(
        wordIndex: (json['w'] as num?)?.toInt() ?? 0,
        startMs: (json['s'] as num?)?.toInt() ?? 0,
        endMs: (json['e'] as num?)?.toInt() ?? 0,
      );
}

class AyahItem {
  final int numberInSurah;
  final String arabic;
  final String banglaTranslation;
  final String banglaTafsir;
  final String transliteration;
  final String audioUrl;
  final String? localAudioPath;
  final List<AyahWord> words;
  final List<WordSegment> segments;

  const AyahItem({
    required this.numberInSurah,
    required this.arabic,
    required this.banglaTranslation,
    required this.banglaTafsir,
    required this.transliteration,
    required this.audioUrl,
    this.localAudioPath,
    this.words = const [],
    this.segments = const [],
  });

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'arabic': arabic,
        'banglaTranslation': banglaTranslation,
        'banglaTafsir': banglaTafsir,
        'transliteration': transliteration,
        'audioUrl': audioUrl,
        'words': words.map((w) => w.toJson()).toList(),
        'segments': segments.map((s) => s.toJson()).toList(),
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
        words: (json['words'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(AyahWord.fromJson)
                .toList() ??
            const [],
        segments: (json['segments'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(WordSegment.fromJson)
                .toList() ??
            const [],
      );
}

class QuranTextService {
  final Map<String, List<AyahItem>> _cache = {};
  final Map<String, Map<int, String>> _tafsirCache = {};

  Future<Map<int, String>> fetchTafsir(int surahNumber, int tafsirId) async {
    if (tafsirId == 0) return const {};
    final key = '${tafsirId}_$surahNumber';
    if (_tafsirCache.containsKey(key)) return _tafsirCache[key]!;

    final url =
        'https://api.quran.com/api/v4/tafsirs/$tafsirId/by_chapter/$surahNumber?per_page=300';
    final raw = await fetchTextUrl(url, timeout: const Duration(seconds: 15));
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['tafsirs'] as List<dynamic>?) ?? const [];
    final map = <int, String>{};
    for (final item in list.whereType<Map<String, dynamic>>()) {
      final vk = (item['verse_key'] as String?) ?? '';
      final parts = vk.split(':');
      if (parts.length != 2) continue;
      final aNum = int.tryParse(parts[1]);
      if (aNum == null) continue;
      final htmlText = (item['text'] as String?) ?? '';
      final clean = htmlText
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (clean.isNotEmpty) map[aNum] = clean;
    }
    _tafsirCache[key] = map;
    return map;
  }

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

    final cloudAudioEdition = qariId.startsWith('qc.') ? 'ar.alafasy' : qariId;
    final url =
        'https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,bn.bengali,bn.hoque,$cloudAudioEdition';
    final body = await fetchTextUrl(url);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final editions = decoded['data'] as List<dynamic>;

    // Fetch IndoPak Arabic script from Zikr Companion server (fallback to Uthmani if offline)
    final indoMap = <int, String>{};
    try {
      final indoBody = await fetchTextUrl(
        'https://zikr-companion.nexterp.bd/public/quran_indo/$surahNumber.json',
        timeout: const Duration(seconds: 8),
      );
      final indoList = jsonDecode(indoBody) as List<dynamic>;
      for (final row in indoList.whereType<Map<String, dynamic>>()) {
        final a = (row['ayah'] as num?)?.toInt();
        final t = (row['text'] as String?)?.trim() ?? '';
        if (a != null && t.isNotEmpty) indoMap[a] = t;
      }
    } catch (_) {}

    // Fetch Word-by-Word (শব্দে শব্দে) data from Zikr Companion server
    final wbwMap = <int, List<AyahWord>>{};
    try {
      final wbwBody = await fetchTextUrl(
        'https://zikr-companion.nexterp.bd/public/quran_wbw/$surahNumber.json',
        timeout: const Duration(seconds: 8),
      );
      final decodedWbw = jsonDecode(wbwBody) as Map<String, dynamic>;
      decodedWbw.forEach((ayahStr, list) {
        final aNum = int.tryParse(ayahStr);
        if (aNum != null && list is List) {
          wbwMap[aNum] = list
              .whereType<Map<String, dynamic>>()
              .map(AyahWord.fromJson)
              .toList();
        }
      });
    } catch (_) {}

    // Fetch exact word-level millisecond timing segments from Quran.com v4
    const recIdMap = <String, int>{
      'ar.alafasy': 7,
      'ar.abdulbasitmurattal': 2,
      'qc.1': 1,
      'qc.3': 3,
      'ar.shaatree': 4,
      'qc.5': 5,
      'ar.husary': 6,
      'qc.12': 12,
      'qc.8': 8,
      'ar.minshawi': 9,
      'qc.10': 10,
      'qc.11': 11,
    };
    final recId = recIdMap[qariId];
    final segAudioMap = <int, String>{};
    final segMap = <int, List<WordSegment>>{};
    if (recId != null) {
      try {
        final segBody = await fetchTextUrl(
          'https://api.quran.com/api/v4/recitations/$recId/by_chapter/$surahNumber?fields=segments',
          timeout: const Duration(seconds: 8),
        );
        final segDecoded = jsonDecode(segBody) as Map<String, dynamic>;
        final audioFiles =
            (segDecoded['audio_files'] as List<dynamic>?) ?? const [];
        for (final af in audioFiles.whereType<Map<String, dynamic>>()) {
          final vk = (af['verse_key'] as String?) ?? '';
          final parts = vk.split(':');
          if (parts.length != 2) continue;
          final aNum = int.tryParse(parts[1]);
          if (aNum == null) continue;
          final rawUrl = (af['url'] as String?) ?? '';
          if (rawUrl.isNotEmpty) {
            segAudioMap[aNum] = rawUrl.startsWith('http')
                ? rawUrl
                : 'https://verses.quran.com/$rawUrl';
          }
          final rawSegs = (af['segments'] as List<dynamic>?) ?? const [];
          final parsedSegs = <WordSegment>[];
          for (final s in rawSegs) {
            if (s is List && s.length >= 4) {
              final wIdx = (s[0] as num).toInt();
              final startMs = (s[2] as num).toInt();
              final endMs = (s[3] as num).toInt();
              parsedSegs.add(WordSegment(
                  wordIndex: wIdx, startMs: startMs, endMs: endMs));
            }
          }
          if (parsedSegs.isNotEmpty) segMap[aNum] = parsedSegs;
        }
      } catch (_) {}
    }

    final arabicAyahs =
        (editions[0]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
    final banglaAyahs =
        (editions[1]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
    final tafsirAyahs =
        (editions[2]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();
    final audioAyahs =
        (editions[3]['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();

    final items = List.generate(arabicAyahs.length, (i) {
      final numInSurah = arabicAyahs[i]['numberInSurah'] as int;
      final arabicText =
          indoMap[numInSurah] ?? (arabicAyahs[i]['text'] as String).trim();
      final fallbackAudio = (audioAyahs[i]['audio'] as String? ?? '').trim();
      return AyahItem(
        numberInSurah: numInSurah,
        arabic: arabicText,
        banglaTranslation: (banglaAyahs[i]['text'] as String).trim(),
        banglaTafsir: (tafsirAyahs[i]['text'] as String).trim(),
        transliteration: '',
        audioUrl: segAudioMap[numInSurah] ?? fallbackAudio,
        words: wbwMap[numInSurah] ?? const [],
        segments: segMap[numInSurah] ?? const [],
      );
    });

    _cache[key] = items;
    return items;
  }

  Future<void> downloadSurahForOffline(
    int surahNumber, {
    String qariId = 'ar.alafasy',
    void Function(int done, int total)? onProgress,
  }) async {
    if (kIsWeb) return;
    final key = _cacheKey(qariId, surahNumber);
    _cache.remove(key);
    final items = await fetchSurahAyahs(surahNumber, qariId: qariId);
    final dir = await _surahDir(qariId, surahNumber);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final updatedItems = <AyahItem>[];
    for (var i = 0; i < items.length; i++) {
        final item = items[i];
        onProgress?.call(i, items.length);
        final mp3File =
            File('${dir.path}${Platform.pathSeparator}${item.numberInSurah}.mp3');

        if (!await mp3File.exists() && item.audioUrl.isNotEmpty) {
          final bytes = await fetchBytesUrl(item.audioUrl,
              timeout: const Duration(seconds: 20));
          if (bytes != null && bytes.isNotEmpty) {
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
  }
}
