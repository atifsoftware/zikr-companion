import 'dart:async';
import 'dart:convert';
import '../utils/io_compat.dart';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/zikr_item.dart';

class ZikrVoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  FlutterTts? _tts;
  bool _initialized = false;
  bool _hasArabicVoice = false;
  bool _hasBanglaVoice = false;
  bool _isCancelled = false;
  Process? _windowsSpeechProcess;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      try {
        _tts ??= FlutterTts();
      } catch (_) {}
      _initialized = true;
      return;
    }
    if (Platform.isWindows) {
      _initialized = true;
      return;
    }

    try {
      _tts ??= FlutterTts();
      await _tts!.awaitSpeakCompletion(true);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);

      final languages = await _tts!.getLanguages;
      if (languages is List) {
        final normalized =
            languages.map((e) => e.toString().toLowerCase()).toList();
        _hasArabicVoice = normalized.any((l) => l.startsWith('ar'));
        _hasBanglaVoice = normalized.any((l) => l.startsWith('bn'));
      }
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<bool> _hasBundledAudio(String id) async {
    try {
      await rootBundle.load('assets/audio/$id.mp3');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> speakZikr(
    ZikrItem item, {
    required int repeatCount,
    double speechRate = 0.45,
    void Function(int completed)? onRepetitionDone,
    VoidCallback? onCompleted,
  }) async {
    await init();
    if (!_initialized) return;

    await stop();
    _isCancelled = false;

    final count = repeatCount < 1 ? 1 : repeatCount;

    if (item.customAudioPath.isNotEmpty) {
      if (item.customAudioPath.startsWith('http://') ||
          item.customAudioPath.startsWith('https://')) {
        await _playAudioSource(
          UrlSource(item.customAudioPath),
          repeatCount: count,
          speechRate: speechRate,
          onRepetitionDone: onRepetitionDone,
        );
        if (!_isCancelled) onCompleted?.call();
        return;
      } else if (!kIsWeb && File(item.customAudioPath).existsSync()) {
        await _playAudioSource(
          DeviceFileSource(item.customAudioPath),
          repeatCount: count,
          speechRate: speechRate,
          onRepetitionDone: onRepetitionDone,
        );
        if (!_isCancelled) onCompleted?.call();
        return;
      }
    }

    if (!item.isCustom && await _hasBundledAudio(item.id)) {
      await _playAudioSource(
        AssetSource('audio/${item.id}.mp3'),
        repeatCount: count,
        speechRate: speechRate,
        onRepetitionDone: onRepetitionDone,
      );
      if (!_isCancelled) onCompleted?.call();
      return;
    }

    if (Platform.isWindows) {
      await _speakOnWindows(
        item,
        repeatCount: count,
        speechRate: speechRate,
        onRepetitionDone: onRepetitionDone,
      );
      if (!_isCancelled) onCompleted?.call();
      return;
    }

    await _speakWithFlutterTts(
      item,
      repeatCount: count,
      speechRate: speechRate,
      onRepetitionDone: onRepetitionDone,
    );
    if (!_isCancelled) onCompleted?.call();
  }

  Future<void> _playAudioSource(
    Source source, {
    required int repeatCount,
    required double speechRate,
    void Function(int completed)? onRepetitionDone,
  }) async {
    // Map speechRate (0.25..0.75) to playbackRate (0.85..1.15), 0.45 -> ~1.0
    final playbackRate = (0.75 + speechRate * 0.55).clamp(0.8, 1.25);

    for (var i = 0; i < repeatCount; i++) {
      if (_isCancelled) break;
      try {
        try {
          await _audioPlayer.setPlaybackRate(playbackRate);
        } catch (_) {}
        final completed = _audioPlayer.onPlayerComplete.first;
        await _audioPlayer.play(source);
        await completed.timeout(const Duration(minutes: 5));
        if (!_isCancelled) onRepetitionDone?.call(i + 1);
      } catch (_) {
        break;
      }
      if (_isCancelled || i == repeatCount - 1) break;
      await Future<void>.delayed(const Duration(milliseconds: 650));
    }
  }

  Future<void> _speakOnWindows(
    ZikrItem item, {
    required int repeatCount,
    required double speechRate,
    void Function(int completed)? onRepetitionDone,
  }) async {
    final text = item.englishPhonetic.isNotEmpty
        ? item.englishPhonetic
        : item.banglaPronunciation;
    final sapiRate = ((speechRate - 0.5) * 16).round().clamp(-5, 5);
    final escaped = text.replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Speech
\$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$s.Rate = $sapiRate
for (\$i = 0; \$i -lt $repeatCount; \$i++) {
  \$s.Speak('$escaped')
  if (\$i -lt ($repeatCount - 1)) { Start-Sleep -Milliseconds 650 }
}
\$s.Dispose()
''';

    final utf16Bytes = Uint8List(script.length * 2);
    final byteData = ByteData.view(utf16Bytes.buffer);
    for (var i = 0; i < script.length; i++) {
      byteData.setUint16(i * 2, script.codeUnitAt(i), Endian.little);
    }
    final encoded = base64Encode(utf16Bytes);

    try {
      _windowsSpeechProcess = await Process.start(
        'powershell',
        ['-NoProfile', '-WindowStyle', 'Hidden', '-EncodedCommand', encoded],
      );
      await _windowsSpeechProcess!.exitCode;
      if (!_isCancelled) onRepetitionDone?.call(repeatCount);
    } catch (_) {
    } finally {
      _windowsSpeechProcess = null;
    }
  }

  Future<void> _speakWithFlutterTts(
    ZikrItem item, {
    required int repeatCount,
    required double speechRate,
    void Function(int completed)? onRepetitionDone,
  }) async {
    final tts = _tts;
    if (tts == null) return;

    await tts.setSpeechRate(speechRate.clamp(0.2, 1.0));

    String textToSpeak;
    String langCode;

    if (_hasArabicVoice && item.arabic.isNotEmpty) {
      langCode = 'ar-SA';
      textToSpeak = item.arabic;
    } else if (item.englishPhonetic.isNotEmpty) {
      langCode = 'en-US';
      textToSpeak = item.englishPhonetic;
    } else if (_hasBanglaVoice) {
      langCode = 'bn-BD';
      textToSpeak = item.banglaPronunciation;
    } else {
      langCode = 'en-US';
      textToSpeak = item.banglaPronunciation;
    }

    try {
      await tts.setLanguage(langCode);
    } catch (_) {}

    for (var i = 0; i < repeatCount; i++) {
      if (_isCancelled) break;
      try {
        await tts.speak(textToSpeak);
        if (!_isCancelled) onRepetitionDone?.call(i + 1);
      } catch (_) {
        break;
      }
      if (_isCancelled || i == repeatCount - 1) break;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  Future<void> stop() async {
    _isCancelled = true;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    final proc = _windowsSpeechProcess;
    if (proc != null) {
      try {
        proc.kill();
      } catch (_) {}
      _windowsSpeechProcess = null;
    }
    if (!Platform.isWindows && _tts != null) {
      try {
        await _tts!.stop();
      } catch (_) {}
    }
  }
}
