import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool soundFx = true;
  bool music = true;
  bool haptics = true;
  bool reducedMotion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SETTINGS"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Sound Effects"),
            subtitle: const Text("Play audio feedback on key presses & game events"),
            value: soundFx,
            onChanged: (val) => setState(() => soundFx = val),
          ),
          SwitchListTile(
            title: const Text("Background Music"),
            subtitle: const Text("Ambient background soundtrack"),
            value: music,
            onChanged: (val) => setState(() => music = val),
          ),
          SwitchListTile(
            title: const Text("Haptic Feedback"),
            subtitle: const Text("Vibrate device on letter guess"),
            value: haptics,
            onChanged: (val) => setState(() => haptics = val),
          ),
          SwitchListTile(
            title: const Text("Reduced Motion"),
            subtitle: const Text("Disable micro-animations for accessibility"),
            value: reducedMotion,
            onChanged: (val) => setState(() => reducedMotion = val),
          ),
          const Divider(height: 32),
          const ListTile(
            title: Text("App Version"),
            trailing: Text("v1.4.3", style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text("Linguistic Data Attribution"),
            subtitle: Text("dwyl/english-words, wordfreq & NLTK WordNet"),
          ),
        ],
      ),
    );
  }
}
