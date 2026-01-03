import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsManager {
  static final TtsManager _instance = TtsManager._internal();
  factory TtsManager() => _instance;

  late FlutterTts _flutterTts;
  bool isAutoPlayEnabled = true; // Varsayılan olarak açık

  TtsManager._internal() {
    _flutterTts = FlutterTts();
    _initTts();
    _loadSettings(); // Ayarları yükle
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
    );
  }

  // Kayıtlı ayarı yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isAutoPlayEnabled = prefs.getBool('auto_tts') ?? true;
  }

  // Ayarı değiştir ve kaydet
  Future<void> toggleAutoPlay(bool value) async {
    isAutoPlayEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_tts', value);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  // Otomatik okuma fonksiyonu (Sadece ayar açıksa okur)
  Future<void> autoSpeak(String text) async {
    if (isAutoPlayEnabled) {
      await speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

final ttsManager = TtsManager();
