import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_manager.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.90);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final words = wordManager.studyList;

    return Scaffold(
      appBar: AppBar(title: Text(wordManager.studyDescription)),
      body: words.isEmpty
          ? const Center(child: Text("Seçili grupta kelime yok."))
          : Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Kart ${_currentIndex + 1} / ${words.length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: words.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildFlipCard(words[index]);
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildFlipCard(Word word) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  word.isInLibrary ? Icons.bookmark : Icons.bookmark_border,
                  size: 30,
                ),
                color: word.isInLibrary ? Colors.orange : Colors.grey,
                onPressed: () =>
                    setState(() => wordManager.toggleLibrary(word)),
              ),
            ),
            const Spacer(),
            Text(
              word.english,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              word.turkish,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "🇺🇸 ${word.sampleEn}",
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: Colors.white),
                  Text(
                    "🇹🇷 ${word.sampleTr}",
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: word.learningScore / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey.shade200,
              color: word.isLearned
                  ? Colors.green
                  : (word.isDeveloping ? Colors.orange : Colors.red),
            ),
            const SizedBox(height: 5),
            Text(
              "%${word.learningScore.toStringAsFixed(0)} Öğrenildi",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
