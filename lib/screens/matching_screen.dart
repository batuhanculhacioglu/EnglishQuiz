import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_manager.dart';
import '../services/sound_manager.dart'; // Ses için import

class MatchingScreen extends StatefulWidget {
  final List<Word> sourceWords;
  const MatchingScreen({super.key, required this.sourceWords});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  // Tüm havuz
  late List<Word> _allGameWords;
  // Şu anki seviyede (ekranda) olan kelimeler
  List<Word> _currentLevelWords = [];

  // Sol (İngilizce) ve Sağ (Türkçe) listeler - Karışık sırada olacaklar
  List<Word> _englishList = [];
  List<Word> _turkishList = [];

  // Seçim durumu
  Word? _selectedWord;
  bool? _isSelectionFromEnglishSide; // true: sol, false: sağ

  // Oyun Durumu
  int _lives = 3;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Ana listeyi bozmamak için kopyasını alıp karıştırıyoruz
    _allGameWords = List.from(widget.sourceWords)..shuffle();
    _loadNextLevel();
  }

  void _loadNextLevel() {
    // Oyun bitti mi kontrolü (Kelime kalmadıysa)
    if (_allGameWords.isEmpty && _currentLevelWords.isEmpty) {
      _finishGame(true);
      return;
    }

    setState(() {
      // Havuzdan 10 tane (veya ne kadar kaldıysa) çek
      int countToTake = _allGameWords.length >= 10 ? 10 : _allGameWords.length;
      _currentLevelWords = _allGameWords.take(countToTake).toList();
      _allGameWords.removeRange(0, countToTake);

      // Listeleri hazırla ve karıştır
      _englishList = List.from(_currentLevelWords)..shuffle();
      _turkishList = List.from(_currentLevelWords)..shuffle();
    });
  }

  void _handleTap(Word word, bool isEnglishSide) {
    if (_lives <= 0) return;

    setState(() {
      // 1. Durum: Henüz hiçbir şey seçilmemiş
      if (_selectedWord == null) {
        _selectedWord = word;
        _isSelectionFromEnglishSide = isEnglishSide;
      }
      // 2. Durum: Aynı taraftan seçim yapıldı (Seçimi değiştir)
      else if (_isSelectionFromEnglishSide == isEnglishSide) {
        _selectedWord = word;
      }
      // 3. Durum: Karşı taraftan seçim yapıldı (Eşleştirme Kontrolü)
      else {
        if (_selectedWord == word) {
          // --- DOĞRU EŞLEŞME ---
          // Listelerden sil
          _englishList.remove(word);
          _turkishList.remove(word);

          // Puan güncelle (Çarpan: 0.5 - Yarım Puan)
          wordManager.updateScore(word, true);
          _score += 5;

          // Seçimi sıfırla
          _selectedWord = null;
          _isSelectionFromEnglishSide = null;

          // Eğer ekrandaki kelimeler bittiyse (10'lu set tamamlandı)
          if (_englishList.isEmpty) {
            soundManager.playCorrect(); // Sadece set bitince SES çal
            // Kısa bir bekleme ve sonraki seviye
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _loadNextLevel();
            });
          }
        } else {
          // --- YANLIŞ EŞLEŞME ---
          _lives--;
          // Yanlış bilindiğinde de puan düşer
          wordManager.updateScore(word, false);

          // Seçimi sıfırla
          _selectedWord = null;
          _isSelectionFromEnglishSide = null;

          if (_lives <= 0) {
            soundManager.playWrong(); // Can bitince SES çal
            _finishGame(false);
          }
        }
      }
    });
  }

  void _finishGame(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(success ? "Tebrikler!" : "Oyun Bitti"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 50,
              color: success ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              success ? "Tüm kelimeleri eşleştirdiniz." : "Haklarınız tükendi.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Toplam Puan: $_score",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Menüye Dön"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelime Eşleştirme"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "Can: $_lives   Puan: $_score",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // --- SOL SÜTUN (İNGİLİZCE) ---
          Expanded(
            child: Container(
              color: Colors.indigo.shade50,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _englishList.length,
                itemBuilder: (context, index) {
                  final word = _englishList[index];
                  final isSelected =
                      (_selectedWord == word &&
                      _isSelectionFromEnglishSide == true);
                  return _buildCard(
                    word.english,
                    isSelected,
                    () => _handleTap(word, true),
                  );
                },
              ),
            ),
          ),

          // Ayırıcı Çizgi
          const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),

          // --- SAĞ SÜTUN (TÜRKÇE) ---
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _turkishList.length,
                itemBuilder: (context, index) {
                  final word = _turkishList[index];
                  final isSelected =
                      (_selectedWord == word &&
                      _isSelectionFromEnglishSide == false);
                  return _buildCard(
                    word.turkish,
                    isSelected,
                    () => _handleTap(word, false),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
