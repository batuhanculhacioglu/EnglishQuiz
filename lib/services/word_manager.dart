import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import '../utils.dart'; // scaffoldMessengerKey burada tanımlı olmalı

class WordManager extends ChangeNotifier {
  List<WordDataset> datasets = [];
  WordDataset? currentDataset;
  bool isLoading = true;

  // Seçim Mekanizması
  List<Word> _studyList = [];
  String _studyDescription = "Henüz seçim yapılmadı";

  List<Word> get studyList => _studyList;
  String get studyDescription => _studyDescription;

  // GLOBAL LİSTE
  List<Word> get allGlobalWords {
    final uniqueWords = <Word>{};
    for (var dataset in datasets) {
      uniqueWords.addAll(dataset.words);
    }
    return uniqueWords.toList();
  }

  // Singleton
  static final WordManager _instance = WordManager._internal();
  factory WordManager() => _instance;
  WordManager._internal() {
    loadFromStorage();
  }

  void setStudyList(List<Word> words, String description) {
    _studyList = words;
    _studyDescription = description;
    notifyListeners();
  }

  // --- STORAGE & LOADING ---

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(datasets.map((e) => e.toJson()).toList());
    await prefs.setString('saved_datasets', encodedData);
    if (currentDataset != null) {
      await prefs.setString('last_dataset_name', currentDataset!.name);
    }
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_datasets');

    if (savedData != null && savedData.isNotEmpty) {
      try {
        Iterable l = jsonDecode(savedData);
        datasets = List<WordDataset>.from(
          l.map((model) => WordDataset.fromJson(model)),
        );

        String? lastName = prefs.getString('last_dataset_name');
        if (datasets.isNotEmpty) {
          if (lastName != null && datasets.any((d) => d.name == lastName)) {
            currentDataset = datasets.firstWhere((d) => d.name == lastName);
          } else {
            currentDataset = datasets.first;
          }
        }
      } catch (e) {
        debugPrint("Veri yükleme hatası: $e");
        await loadDefaultAssets();
      }
    } else {
      await loadDefaultAssets();
    }

    if (currentDataset != null) {
      setStudyList(currentDataset!.words, "Set: ${currentDataset!.name}");
    }

    isLoading = false;
    notifyListeners();
  }

  // --- ASSET LOADING ---

  Future<void> loadDefaultAssets() async {
    List<String> files = [
      'assets/csv/a1_words.csv',
      'assets/csv/a2_words.csv',
      'assets/csv/b1_words.csv',
      'assets/csv/b2_words.csv',
      'assets/csv/c1_words.csv',
      'assets/csv/c2_words.csv',
    ];

    for (var path in files) {
      try {
        String content = await rootBundle.loadString(path);
        String levelName = path.split('/').last.split('_').first.toUpperCase();
        // Assetleri yüklerken hata diyalogu açma, sessizce yükle
        _parseAndAddDataset(content, "Seviye $levelName", levelName);
      } catch (e) {
        debugPrint("Asset yüklenemedi: $path");
      }
    }

    if (datasets.isNotEmpty) {
      currentDataset = datasets.first;
    }
    await saveToStorage();
  }

  // --- PARSE FONKSİYONU (Regex Hatasından Arındırılmış) ---
  String? _parseAndAddDataset(
    String content,
    String setName,
    String difficulty,
  ) {
    try {
      // 1. ADIM: Satır sonlarını düzelt (Mac/Windows uyumu)
      // Bu adım SampleTrHello gibi yapışık satırları ayırır
      String cleanContent = content
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');

      // Regex hatası alıyordun, bu yüzden [source] temizliğini BASİT string değişimiyle yapıyoruz
      // Eğer dosyanın içinde gibi şeyler varsa temizler, yoksa dokunmaz.
      // (Daha karmaşık regex kullanmıyoruz ki hata vermesin)

      // 2. ADIM: CSV Dönüştürme
      // Ayırıcıyı (virgül mü noktalı virgül mü) otomatik bul
      String delimiter = ',';
      if (cleanContent.contains(';') &&
          cleanContent.split(';').length > cleanContent.split(',').length) {
        delimiter = ';';
      }

      List<List<dynamic>> rows = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(cleanContent);

      List<Word> newWords = [];

      for (int i = 0; i < rows.length; i++) {
        var row = rows[i];

        // Boş satırları atla
        if (row.isEmpty) continue;
        if (row.length == 1 && row[0].toString().trim().isEmpty) continue;

        // Yetersiz sütun varsa atla
        if (row.length < 2) continue;

        String eng = row[0].toString().trim();
        String tr = row[1].toString().trim();

        // Başlık satırlarını atla
        if (eng.toLowerCase() == 'english' || eng.toLowerCase() == 'ingilizce')
          continue;
        if (eng.isEmpty || tr.isEmpty) continue;

        String sampleEn = "";
        String sampleTr = "";

        if (row.length > 2) sampleEn = row[2].toString().trim();
        if (row.length > 3) sampleTr = row[3].toString().trim();

        newWords.add(
          Word(
            english: eng,
            turkish: tr,
            sampleEn: sampleEn,
            sampleTr: sampleTr,
          ),
        );
      }

      if (newWords.isNotEmpty) {
        datasets.add(
          WordDataset(name: setName, words: newWords, difficulty: difficulty),
        );
        debugPrint("✅ BAŞARILI: ${newWords.length} kelime eklendi.");
        return null; // Başarılı
      } else {
        return "Hiçbir kelime okunamadı. Satırlar düzgün ayrılmamış olabilir.";
      }
    } catch (e) {
      debugPrint("HATA DETAYI: $e");
      return "Program hatası: $e";
    }
  }

  // --- IMPORT CSV ---

  Future<void> importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null) {
        PlatformFile pFile = result.files.single;

        String content;
        if (pFile.bytes != null) {
          content = utf8.decode(pFile.bytes!);
        } else {
          File file = File(pFile.path!);
          content = await file.readAsString();
        }

        String name = pFile.name.replaceAll('.csv', '').replaceAll('.txt', '');

        // Parse işlemini çağır
        String? errorMsg = _parseAndAddDataset(content, name, "Özel");

        if (errorMsg == null) {
          // Başarılı
          await saveToStorage();
          if (datasets.isNotEmpty) {
            selectDataset(datasets.last);
          }
          notifyListeners();

          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text("$name eklendi."),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Hata Mesajı
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text("HATA: $errorMsg"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text("Dosya hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    datasets.clear();
    currentDataset = null;
    await loadDefaultAssets();
    notifyListeners();
  }

  // --- ACTIONS ---

  void selectDataset(WordDataset dataset) {
    currentDataset = dataset;
    setStudyList(dataset.words, "Set: ${dataset.name}");
    saveToStorage();
    notifyListeners();
  }

  void toggleLibrary(Word word) {
    word.isInLibrary = !word.isInLibrary;
    saveToStorage();
    notifyListeners();
  }

  void updateScore(Word word, bool isCorrect) {
    if (isCorrect) {
      double gap = 100.0 - word.learningScore;
      word.learningScore += gap * 0.20;
    } else {
      word.learningScore = word.learningScore / 2;
    }
    saveToStorage();
    notifyListeners();
  }
}

final wordManager = WordManager();
