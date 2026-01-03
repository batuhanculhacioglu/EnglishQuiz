import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_manager.dart';
import '../services/tts_manager.dart';

class QuizScreen extends StatefulWidget {
  final List<Word> sourceWords;
  const QuizScreen({super.key, required this.sourceWords});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Word> _sessionWords;
  Word? _currentQuestion;
  List<Word> _options = [];
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _sessionWords = List.from(widget.sourceWords);
    if (_sessionWords.isEmpty) return;
    _sessionWords.shuffle();
    if (_sessionWords.length > 20)
      _sessionWords = _sessionWords.take(20).toList();
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_sessionWords.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Bitti"),
          content: const Text("Test tamamlandı."),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("Çıkış"),
            ),
          ],
        ),
      );

      if (_currentQuestion != null) {
        ttsManager.autoSpeak(_currentQuestion!.english);
      }
      return;
    }

    setState(() {
      _answered = false;
      _currentQuestion = _sessionWords.first;
      _sessionWords.removeAt(0);

      List<Word> pool = List.from(widget.sourceWords)..remove(_currentQuestion);
      // Havuz yetersizse globalden destek al
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
  }

  void _handleAnswer(Word selected) {
    if (_answered) return;
    bool correct = (selected == _currentQuestion);
    wordManager.updateScore(_currentQuestion!, correct);
    setState(() {
      _answered = true;
      _isCorrect = correct;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion == null)
      return const Scaffold(body: Center(child: Text("Yetersiz Kelime")));

    return Scaffold(
      appBar: AppBar(title: const Text("Test Modu")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                          icon: const Icon(
                            Icons.volume_up,
                            color: Colors.indigo,
                          ),
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
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
