// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui';

class WebAudioPlayer {
  html.AudioElement? _audio;
  StreamSubscription? _endedSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _errorSub;
  Timer? _posTimer;

  VoidCallback? onComplete;
  VoidCallback? onPlaying;
  void Function(String err)? onError;
  void Function(double progress)? onProgress;
  void Function(int positionMs)? onPositionMs;

  Future<void> playUrl(String url) async {
    await stop();
    final audio = html.AudioElement(url);
    audio.preload = 'auto';
    _audio = audio;

    _endedSub = audio.onEnded.listen((_) {
      _posTimer?.cancel();
      onComplete?.call();
    });
    _playingSub = audio.onPlaying.listen((_) => onPlaying?.call());
    _errorSub = audio.onError.listen((_) {
      _posTimer?.cancel();
      onError?.call('অডিও লোড করা যায়নি');
    });

    _posTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final a = _audio;
      if (a == null || a.paused) return;
      final ms = (a.currentTime * 1000).round();
      onPositionMs?.call(ms);
      final dur = a.duration;
      if (dur.isFinite && dur > 0) {
        onProgress?.call((a.currentTime / dur).clamp(0.0, 1.0));
      }
    });

    await audio.play();
  }

  Future<void> pause() async {
    _audio?.pause();
  }

  Future<void> resume() async {
    await _audio?.play();
  }

  Future<void> stop() async {
    _posTimer?.cancel();
    _posTimer = null;
    await _endedSub?.cancel();
    await _playingSub?.cancel();
    await _errorSub?.cancel();
    _endedSub = null;
    _playingSub = null;
    _errorSub = null;
    if (_audio != null) {
      _audio!.pause();
      _audio!.src = '';
      _audio = null;
    }
  }

  void dispose() {
    unawaited(stop());
  }
}
