import 'dart:ui';

class WebAudioPlayer {
  VoidCallback? onComplete;
  VoidCallback? onPlaying;
  void Function(String err)? onError;
  void Function(double progress)? onProgress;
  void Function(int positionMs)? onPositionMs;

  Future<void> playUrl(String url) async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
  void dispose() {}
}
