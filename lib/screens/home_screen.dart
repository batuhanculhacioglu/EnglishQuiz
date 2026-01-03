import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_manager.dart';
import 'study_screen.dart';
import 'time_trial_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    wordManager.addListener(_update);
  }

  @override
  void dispose() {
    wordManager.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (wordManager.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeSet = wordManager.currentDataset;
    final globalWords = wordManager.allGlobalWords;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EnglishQuiz',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, activeSet),
      body: activeSet == null
          ? const Center(child: Text("Lütfen bir set seçin."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. GENEL İSTATİSTİK
                  InkWell(
                    onTap: () {
                      wordManager.setStudyList(globalWords, "Genel (Tümü)");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Seçildi: Tüm Kelimeler"),
                          duration: Duration(milliseconds: 700),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.public, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Text(
                            "Genel İstatistik",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${globalWords.length} Kelime",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildStatRow(
                    context,
                    globalWords,
                    titlePrefix: "Genel",
                    isGlobal: true,
                  ),

                  const SizedBox(height: 25),

                  // 2. SET İSTATİSTİKLERİ
                  InkWell(
                    onTap: () {
                      wordManager.setStudyList(
                        activeSet.words,
                        "Set: ${activeSet.name}",
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Seçildi: ${activeSet.name}"),
                          duration: const Duration(milliseconds: 700),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.folder, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    activeSet.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "%${activeSet.progressPercentage.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildStatRow(context, activeSet.words, titlePrefix: "Set"),

                  const SizedBox(height: 30),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 10),

                  // 3. SEÇİLİ KAYNAK BİLGİSİ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "SEÇİLİ KAYNAK",
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${wordManager.studyDescription} (${wordManager.studyList.length} Kelime)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 4. AKSİYON BUTONLARI
                  SizedBox(
                    height: 110,
                    child: Row(
                      children: [
                        _gridButton(
                          context,
                          title: "Zamana\nKarşı",
                          icon: Icons.timer,
                          color: Colors.red.shade100,
                          iconColor: Colors.red.shade900,
                          onTap: () {
                            if (wordManager.studyList.length < 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Seçili grupta en az 5 kelime olmalı!",
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TimeTrialScreen(
                                    words: wordManager.studyList,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _gridButton(
                          context,
                          title: "Test\nÇöz",
                          icon: Icons.quiz,
                          color: Colors.orange.shade100,
                          iconColor: Colors.orange.shade900,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                sourceWords: wordManager.studyList,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _gridButton(
                          context,
                          title: "Kelime\nKartları",
                          icon: Icons.style,
                          color: Colors.blue.shade100,
                          iconColor: Colors.blue.shade900,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudyScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _gridButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    List<Word> words, {
    bool isGlobal = false,
    required String titlePrefix,
  }) {
    var newW = words.where((w) => w.isNew).toList();
    var weakW = words.where((w) => w.isWeak).toList();
    var devW = words.where((w) => w.isDeveloping).toList();
    var learnW = words.where((w) => w.isLearned).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isGlobal
            ? Border.all(color: Colors.grey.shade300)
            : Border.all(color: Colors.indigo.shade100, width: 2),
      ),
      child: Row(
        children: [
          _selectableStatItem(
            context,
            "Yeni",
            newW,
            Colors.grey,
            Icons.fiber_new,
            "$titlePrefix - Yeni",
          ),
          _divider(),
          _selectableStatItem(
            context,
            "Zayıf",
            weakW,
            Colors.red,
            Icons.warning_amber_rounded,
            "$titlePrefix - Zayıf",
          ),
          _divider(),
          _selectableStatItem(
            context,
            "Gelişiyor",
            devW,
            Colors.orange,
            Icons.trending_up,
            "$titlePrefix - Gelişiyor",
          ),
          _divider(),
          _selectableStatItem(
            context,
            "Öğrenildi",
            learnW,
            Colors.green,
            Icons.check_circle_outline,
            "$titlePrefix - Öğrenildi",
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Widget _selectableStatItem(
    BuildContext context,
    String label,
    List<Word> words,
    Color color,
    IconData icon,
    String fullDescription,
  ) {
    bool isSelected = wordManager.studyDescription == fullDescription;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (words.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bu kategoride hiç kelime yok!")),
            );
            return;
          }
          wordManager.setStudyList(words, fullDescription);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Seçildi: $fullDescription"),
              backgroundColor: color,
              duration: const Duration(milliseconds: 500),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color),
                )
              : null,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                "${words.length}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSelected)
                Icon(Icons.arrow_drop_down, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WordDataset? activeSet) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.indigo),
            accountName: const Text("EnglishQuiz"),
            accountEmail: Text(
              activeSet != null
                  ? "Seçili: ${activeSet.name}"
                  : "Seçili Set Yok",
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.school, color: Colors.indigo),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
            title: const Text("Yeni Set Ekle (CSV)"),
            onTap: () {
              Navigator.pop(context);
              wordManager.importCsv();
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: wordManager.datasets.length,
              itemBuilder: (context, index) {
                final dataset = wordManager.datasets[index];
                return ListTile(
                  selected: dataset == activeSet,
                  selectedTileColor: Colors.indigo.shade50,
                  leading: Icon(
                    Icons.folder_open,
                    color: dataset == activeSet ? Colors.indigo : Colors.grey,
                  ),
                  title: Text(dataset.name),
                  subtitle: Text(
                    "%${dataset.progressPercentage.toStringAsFixed(0)} Tamamlandı",
                  ),
                  onTap: () {
                    wordManager.selectDataset(dataset);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Verileri Sıfırla"),
            onTap: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text("Sıfırla"),
                  content: const Text("Tüm veriler silinecek."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.pop(context);
                        wordManager.resetAllData();
                      },
                      child: const Text(
                        "SİL",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
