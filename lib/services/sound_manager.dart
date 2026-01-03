import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  final AudioPlayer _player = AudioPlayer();

  SoundManager._internal();

  Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print("Ses çalma hatası: $e");
    }
  }

  Future<void> playWrong() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      print("Ses çalma hatası: $e");
    }
  }
}

final soundManager = SoundManager();
