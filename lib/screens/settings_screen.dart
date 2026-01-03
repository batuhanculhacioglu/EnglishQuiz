import 'package:flutter/material.dart';
import '../services/tts_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Otomatik Sesli Okuma"),
            subtitle: const Text(
              "Sorular ve kartlar geldiğinde İngilizcesini otomatik oku.",
            ),
            value: ttsManager.isAutoPlayEnabled,
            activeColor: Colors.indigo,
            onChanged: (bool value) {
              setState(() {
                ttsManager.toggleAutoPlay(value);
              });
            },
          ),
        ],
      ),
    );
  }
}
