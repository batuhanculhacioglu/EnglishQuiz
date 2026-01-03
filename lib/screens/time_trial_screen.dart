import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_manager.dart';
import '../services/tts_manager.dart';

class TimeTrialScreen extends StatefulWidget {
  final List<Word> words;
  const TimeTrialScreen({super.key, required this.words});

  @override
  State<TimeTrialScreen> createState() => _TimeTrialScreenState();
}

class _TimeTrialScreenState extends State<TimeTrialScreen> {
  late Timer _timer;
  int _remainingSeconds = 60;
  int _scoreCount = 0;

  late List<Word> _gameWords;
  Word? _currentQuestion;
  List<Word> _options = [];
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _gameWords = List.from(widget.words)..shuffle();
    _startTimer();
    _nextQuestion();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Süre Bitti!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 50, color: Colors.orange),
            const SizedBox(height: 10),
            Text(
              "Skor: $_scoreCount",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Menü"),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_gameWords.isEmpty) {
      _gameWords = List.from(widget.words)..shuffle();
    }

    setState(() {
      _answered = false;
      _currentQuestion = _gameWords.first;
      _gameWords.removeAt(0);

      List<Word> pool = List.from(widget.words)..remove(_currentQuestion);
      // Şık havuzu yetersizse globalden takviye yap
      if (pool.length < 4) {
        var globalPool = List.from(wordManager.allGlobalWords)
          ..remove(_currentQuestion);
        for (var w in globalPool) {
          if (!pool.contains(w)) pool.add(w);
          if (pool.length >= 10) break;
        }
      }

      pool.shuffle();
      _options = [_currentQuestion!];
      _options.addAll(pool.take(4));
      _options.shuffle();
    });

    if (_currentQuestion != null) {
      ttsManager.autoSpeak(_currentQuestion!.english);
    }
  }

  void _handleAnswer(Word selected) {
    if (_answered || _remainingSeconds <= 0) return;

    bool correct = (selected == _currentQuestion);
    wordManager.updateScore(_currentQuestion!, correct);

    setState(() {
      _answered = true;
      _isCorrect = correct;
      if (correct) {
        _scoreCount++;
        _remainingSeconds += 1;
      } else {
        _remainingSeconds -= 10;
      }
    });

    if (_remainingSeconds <= 0) {
      _endGame();
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _remainingSeconds > 0) _nextQuestion();
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$_remainingSeconds sn",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text("Puan: $_scoreCount")),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _remainingSeconds / 60,
            backgroundColor: Colors.red.shade100,
            color: _remainingSeconds > 20 ? Colors.green : Colors.red,
            minHeight: 10,
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentQuestion!.english,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.indigo),
                        onPressed: () =>
                            ttsManager.speak(_currentQuestion!.english),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _currentQuestion!.sampleEn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _options.length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final opt = _options[index];
                Color btnColor = Colors.white;
                if (_answered) {
                  if (opt == _currentQuestion)
                    btnColor = Colors.green.shade100;
                  else if (opt == _options[index] && !_isCorrect)
                    btnColor = Colors.red.shade100;
                }
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _handleAnswer(opt),
                  child: Text(
                    opt.turkish,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
