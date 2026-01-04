import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  final AudioPlayer _player = AudioPlayer();

  SoundManager._internal();

  // Ses çal ve bitene kadar bekle
  Future<void> playCorrect() async {
    try {
      await _player.stop();
      await _player.setVolume(0.5);
      await _player.play(AssetSource('sounds/success.mp3'));
      // Ses bitene kadar bekle (veya en fazla 2 saniye bekle ki uygulama donmasın)
      await _player.onPlayerComplete.first.timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }

  Future<void> playWrong() async {
    try {
      await _player.stop();
      await _player.setVolume(0.5);
      await _player.play(AssetSource('sounds/wrong.mp3'));
      await _player.onPlayerComplete.first.timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }
}

final soundManager = SoundManager();
