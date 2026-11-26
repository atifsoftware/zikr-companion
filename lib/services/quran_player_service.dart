import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/surah_data.dart';
import '../utils/web_audio_player.dart';
import 'quran_text_service.dart';

class QuranPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final WebAudioPlayer _webPlayer = WebAudioPlayer();
  final QuranTextService _textService = QuranTextService();

  QariInfo _selectedQari = QariInfo.presets.first;
  TafsirInfo _selectedTafsir = TafsirInfo.presets.first;
  Map<int, String> _remoteTafsirMap = const {};
  bool _isLoadingTafsir = false;
  SurahInfo? _currentSurah;
  int _currentAyahIndex = 0;
  PlayerState _playerState = PlayerState.stopped;
  bool _isLoadingAudio = false;
  bool _isLoadingText = false;
  bool _isDownloading = false;
  bool _isCurrentDownloaded = false;
  int _downloadDone = 0;
  int _downloadTotal = 0;
  List<AyahItem> _ayahs = [];
  String? _errorText;
  String? _textError;
  double _ayahProgress = 0.0;
  int _positionMs = 0;
  Duration _audioDuration = Duration.zero;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<Duration>? _posSub;

  QuranPlayerService() {
    if (kIsWeb) {
      _webPlayer.onPlaying = () {
        _playerState = PlayerState.playing;
        _isLoadingAudio = false;
        _errorText = null;
        notifyListeners();
      };
      _webPlayer.onProgress = (progress) {
        _ayahProgress = progress;
        notifyListeners();
      };
      _webPlayer.onPositionMs = (ms) {
        _positionMs = ms;
        notifyListeners();
      };
      _webPlayer.onComplete = () {
        _ayahProgress = 0.0;
        _positionMs = 0;
        if (_currentAyahIndex + 1 < _ayahs.length) {
          playAyahAt(_currentAyahIndex + 1);
        } else {
          _playerState = PlayerState.stopped;
          _isLoadingAudio = false;
          notifyListeners();
        }
      };
      _webPlayer.onError = (err) {
        _ayahProgress = 0.0;
        _isLoadingAudio = false;
        _playerState = PlayerState.stopped;
        _errorText = 'অডিও প্লে করা যায়নি — ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        notifyListeners();
      };
    } else {
      _stateSub = _player.onPlayerStateChanged.listen((state) {
        _playerState = state;
        if (state == PlayerState.playing) {
          _isLoadingAudio = false;
        }
        notifyListeners();
      });
      _durSub = _player.onDurationChanged.listen((d) {
        _audioDuration = d;
      });
      _posSub = _player.onPositionChanged.listen((pos) {
        _positionMs = pos.inMilliseconds;
        if (_audioDuration.inMilliseconds > 0) {
          _ayahProgress =
              (pos.inMilliseconds / _audioDuration.inMilliseconds)
                  .clamp(0.0, 1.0);
        }
        notifyListeners();
      });
      _completeSub = _player.onPlayerComplete.listen((_) {
        _ayahProgress = 0.0;
        _positionMs = 0;
        if (_currentAyahIndex + 1 < _ayahs.length) {
          playAyahAt(_currentAyahIndex + 1);
        } else {
          _playerState = PlayerState.stopped;
          _isLoadingAudio = false;
          notifyListeners();
        }
      });
    }
    selectSurah(SurahInfo.all114.first, autoPlay: false);
  }

  QariInfo get selectedQari => _selectedQari;
  TafsirInfo get selectedTafsir => _selectedTafsir;
  bool get isLoadingTafsir => _isLoadingTafsir;
  SurahInfo? get currentSurah => _currentSurah;

  String tafsirForAyah(AyahItem ayah) {
    if (_selectedTafsir.id != 0) {
      final t = _remoteTafsirMap[ayah.numberInSurah];
      if (t != null && t.isNotEmpty) return t;
    }
    return ayah.banglaTafsir;
  }

  Future<void> setTafsir(TafsirInfo tafsir) async {
    _selectedTafsir = tafsir;
    final surah = _currentSurah;
    if (surah == null || tafsir.id == 0) {
      _remoteTafsirMap = const {};
      notifyListeners();
      return;
    }
    _isLoadingTafsir = true;
    notifyListeners();
    try {
      _remoteTafsirMap =
          await _textService.fetchTafsir(surah.number, tafsir.id);
    } catch (_) {
      _remoteTafsirMap = const {};
    } finally {
      _isLoadingTafsir = false;
      notifyListeners();
    }
  }
  int get currentAyahIndex => _currentAyahIndex;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isActiveSession =>
      _currentSurah != null &&
      (_playerState == PlayerState.playing ||
          _playerState == PlayerState.paused ||
          _isLoadingAudio);
  bool get isLoadingAudio => _isLoadingAudio;
  bool get isLoadingText => _isLoadingText;
  bool get isDownloading => _isDownloading;
  bool get isCurrentDownloaded => _isCurrentDownloaded;
  int get downloadDone => _downloadDone;
  int get downloadTotal => _downloadTotal;
  List<AyahItem> get ayahs => List.unmodifiable(_ayahs);
  String? get errorText => _errorText;
  String? get textError => _textError;
  double get ayahProgress => _ayahProgress;
  int get currentPositionMs => _positionMs;

  int activeWordIndexFor(AyahItem ayah) {
    if (!isPlaying || ayah.words.isEmpty) return -1;
    if (ayah.segments.isNotEmpty) {
      for (final seg in ayah.segments) {
        if (_positionMs >= seg.startMs && _positionMs <= seg.endMs) {
          return seg.wordIndex.clamp(0, ayah.words.length - 1);
        }
      }
      // If between segments, keep the latest started segment
      int latest = -1;
      for (final seg in ayah.segments) {
        if (_positionMs >= seg.startMs) {
          latest = seg.wordIndex;
        }
      }
      if (latest >= 0) return latest.clamp(0, ayah.words.length - 1);
    }
    return (_ayahProgress * ayah.words.length)
        .floor()
        .clamp(0, ayah.words.length - 1);
  }

  AyahItem? get currentAyah =>
      (_ayahs.isNotEmpty && _currentAyahIndex < _ayahs.length)
          ? _ayahs[_currentAyahIndex]
          : null;

  Future<void> setQari(QariInfo qari) async {
    if (qari.id == _selectedQari.id) return;
    _selectedQari = qari;
    final surah = _currentSurah ?? SurahInfo.all114.first;
    await selectSurah(surah, autoPlay: isPlaying);
  }

  Future<void> selectSurah(SurahInfo surah, {bool autoPlay = true}) async {
    _currentSurah = surah;
    _currentAyahIndex = 0;
    _isLoadingText = true;
    _isLoadingAudio = autoPlay;
    _errorText = null;
    _textError = null;
    _ayahs = [];
    _isCurrentDownloaded = false;
    notifyListeners();

    try {
      await _player.stop();
      final downloaded =
          await _textService.isSurahDownloaded(_selectedQari.id, surah.number);
      final list = await _textService.fetchSurahAyahs(
        surah.number,
        qariId: _selectedQari.id,
      );
      _ayahs = list;
      _isLoadingText = false;
      _isCurrentDownloaded = downloaded;
      if (_selectedTafsir.id != 0) {
        unawaited(setTafsir(_selectedTafsir));
      } else {
        _remoteTafsirMap = const {};
      }
      notifyListeners();

      if (autoPlay && list.isNotEmpty) {
        await playAyahAt(0);
      }
    } catch (_) {
      _isLoadingText = false;
      _isLoadingAudio = false;
      _textError =
          'আয়াত ও তিলাওয়াত লোড করা যায়নি (ইন্টারনেট সংযোগ পরীক্ষা করুন)।';
      notifyListeners();
    }
  }

  Future<void> playAyahAt(int index) async {
    if (index < 0 || index >= _ayahs.length) return;
    final ayah = _ayahs[index];
    if (ayah.localAudioPath == null && ayah.audioUrl.isEmpty) return;

    _currentAyahIndex = index;
    _ayahProgress = 0.0;
    _positionMs = 0;
    _audioDuration = Duration.zero;
    _isLoadingAudio = true;
    _errorText = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        await _webPlayer.playUrl(ayah.audioUrl);
        _playerState = PlayerState.playing;
        _isLoadingAudio = false;
        notifyListeners();
      } else {
        await _player.stop();
        if (ayah.localAudioPath != null) {
          await _player.play(DeviceFileSource(ayah.localAudioPath!));
        } else {
          await _player.play(UrlSource(ayah.audioUrl));
        }
      }
    } catch (_) {
      _isLoadingAudio = false;
      _errorText = 'অডিও প্লে করা যায়নি — ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      if (kIsWeb) {
        await _webPlayer.pause();
        _playerState = PlayerState.paused;
        notifyListeners();
      } else {
        await _player.pause();
      }
    } else if (_playerState == PlayerState.paused) {
      if (kIsWeb) {
        await _webPlayer.resume();
        _playerState = PlayerState.playing;
        notifyListeners();
      } else {
        await _player.resume();
      }
    } else if (_ayahs.isNotEmpty) {
      await playAyahAt(_currentAyahIndex);
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      await _webPlayer.stop();
    } else {
      await _player.stop();
    }
    _isLoadingAudio = false;
    _playerState = PlayerState.stopped;
    notifyListeners();
  }

  Future<void> downloadCurrentSurah() async {
    final surah = _currentSurah;
    if (surah == null || _isDownloading) return;
    _isDownloading = true;
    _downloadDone = 0;
    _downloadTotal = _ayahs.length;
    _errorText = null;
    notifyListeners();

    try {
      await _textService.downloadSurahForOffline(
        surah.number,
        qariId: _selectedQari.id,
        onProgress: (done, total) {
          _downloadDone = done;
          _downloadTotal = total;
          notifyListeners();
        },
      );
      final updated = await _textService.fetchSurahAyahs(
        surah.number,
        qariId: _selectedQari.id,
      );
      _ayahs = updated;
      _isDownloading = false;
      _isCurrentDownloaded = true;
      notifyListeners();
    } catch (_) {
      _isDownloading = false;
      _errorText = 'অফলাইন ডাউনলোড ব্যর্থ হয়েছে — ইন্টারনেট পরীক্ষা করুন।';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _completeSub?.cancel();
    _durSub?.cancel();
    _posSub?.cancel();
    _webPlayer.dispose();
    _player.dispose();
    super.dispose();
  }
}
