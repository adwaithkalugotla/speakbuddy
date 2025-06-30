import 'package:flutter/material.dart';
import 'speaker_info_screen.dart';
import '../main.dart'; // ✅ HomePage route

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _navigateToSpeakerInfo(BuildContext context, String mode, String format) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpeakerInfoScreen(
          mode: mode,
          onContinue: (s1, s2, t, f, mode) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(
                  speaker1: s1,
                  speaker2: s2,
                  topic: t,
                  format: format,
                  mode: mode,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[700],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 👨‍⚖️ Logo
                Image.asset(
                  'lib/assets/speakbuddy_logo.png',
                  height: 140,
                ),
                const SizedBox(height: 24),

                // App Title
                const Text(
                  "SpeakBuddy",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                const Text(
                  "Present your case. Settle your debate.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "Choose your debate mode:",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 30),

                // Auto Debate Mode Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings_voice),
                  label: const Text("Auto Debate Mode"),
                  onPressed: () => _navigateToSpeakerInfo(context, "auto", "lincoln_douglas"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),

                // Normal Mode Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.handyman),
                  label: const Text("Normal Mode"),
                  onPressed: () => _navigateToSpeakerInfo(context, "normal", "lincoln_douglas"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 40),

                // Mode Info Text
                const Text(
                  "🤖 Auto Mode: App manages timing & round flow.\n🛠️ Normal Mode: You control everything manually.",
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
