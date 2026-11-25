import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/surah_data.dart';
import 'quran_text_service.dart';

class QuranPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final QuranTextService _textService = QuranTextService();

  QariInfo _selectedQari = QariInfo.presets.first;
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

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  QuranPlayerService() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.playing) {
        _isLoadingAudio = false;
      }
      notifyListeners();
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (_currentAyahIndex + 1 < _ayahs.length) {
        playAyahAt(_currentAyahIndex + 1);
      } else {
        _playerState = PlayerState.stopped;
        _isLoadingAudio = false;
        notifyListeners();
      }
    });
    selectSurah(SurahInfo.all114.first, autoPlay: false);
  }

  QariInfo get selectedQari => _selectedQari;
  SurahInfo? get currentSurah => _currentSurah;
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
    _isLoadingAudio = true;
    _errorText = null;
    notifyListeners();

    try {
      await _player.stop();
      if (ayah.localAudioPath != null) {
        await _player.play(DeviceFileSource(ayah.localAudioPath!));
      } else {
        await _player.play(UrlSource(ayah.audioUrl));
      }
    } catch (_) {
      _isLoadingAudio = false;
      _errorText = 'অডিও প্লে করা যায়নি — ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else if (_ayahs.isNotEmpty) {
      await playAyahAt(_currentAyahIndex);
    }
  }

  Future<void> stop() async {
    await _player.stop();
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
    _player.dispose();
    super.dispose();
  }
}
