

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; 
import 'dart:async'; // <-- NEW for Timer
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
//import 'package:path_provider_android/path_provider_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'screens/speaker_info_screen.dart';
//import 'package:flutter_tts/flutter_tts.dart';
import 'screens/mode_selection_screen.dart';
import 'controllers/auto_debate_controller.dart';
import 'models/round_models.dart';
import 'package:flutter/services.dart' show rootBundle;


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String? speaker1;
  String? speaker2;
  String? topic;
  String? format;


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ModeSelectionScreen(),

    );
  }
}

class HomePage extends StatefulWidget {
  final String speaker1;
  final String speaker2;
  final String topic;
  final String format;
  final String mode;


  const HomePage({
    super.key,
    required this.speaker1,
    required this.speaker2,
    required this.topic,
    required this.format,
    required this.mode,
  });

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  late final String speaker1;
late final String speaker2;
late final String topic;
late final String mode;

AutoDebateController? _controller;
String _currentRoundLabel = "";



 int _currentAutoRoundIndex = 0;

  final List<Map<String, dynamic>> _autoDebateRounds = [
    {"label": "Pro Constructive", "duration": 240},  // 4 minutes
    {"label": "Cross Examination", "duration": 180}, // 3 minutes
    {"label": "Con Constructive", "duration": 240},
    {"label": "Pro Rebuttal", "duration": 240},
    {"label": "Con Rebuttal", "duration": 240},
    {"label": "Pro Summary", "duration": 120},
    {"label": "Con Summary", "duration": 120},
    {"label": "Grand Crossfire", "duration": 180},
    {"label": "Pro Final Focus", "duration": 120},
    {"label": "Con Final Focus", "duration": 120},
  ];

@override
void initState() {
  super.initState();
  speaker1 = widget.speaker1;
  speaker2 = widget.speaker2;
  topic = widget.topic;
  mode = widget.mode;

}

  String analysisResult = "";
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isPaused = false;
List<Map<String, dynamic>> _recordedRounds = [];





  Timer? _timer; // <-- NEW
int _secondsElapsed = 0; // <-- NEW

  /// Helper to format seconds into MM:SS
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs    = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  /// Build the “Speaking Summary” text from your recorded rounds
String buildRoundSummaryText() {
  String summary = "";
  int total = 0;
  for (var round in _recordedRounds) {
    if (round['skipped'] == true) {
      summary += "${round['label']}: SKIPPED\n";
    } else {
      final int d = round['duration'] as int;
      summary += "${round['label']}: ${_formatDuration(d)}\n";
      total += d;
    }
  }
  summary += "\nTotal Speaking Time: ${_formatDuration(total)}";
  return summary;
}


String get _formattedTime {
  final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
  final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}

void _pauseRecording() async {
  // ── 1. Stop the timer
  _timer?.cancel();

  // ── 2. Save elapsed seconds into the current round entry
  if (_recordedRounds.isNotEmpty) {
    _recordedRounds.last['duration'] = _secondsElapsed;
  }

  // ── 3. Mark as paused
  setState(() {
    _isPaused = true;
  });
}


Future<void> _endCurrentAutoRound() async {
  if (_isRecording) {
    await apiService.stopRecording();
    _setRecording(false);
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Round ended early.")),
    );
  }

  await _advanceToNextAutoRound(); // ⏭️ Proceed properly
}

Future<void> _skipCurrentAutoRound() async {
  // 1) If still recording, stop it
  if (_isRecording) {
    await apiService.stopRecording();
    _setRecording(false);
  }
  // 2) Mark this round as skipped
  final current = _autoDebateRounds[_currentAutoRoundIndex];
  _recordedRounds.add({
    'label': current['label'],
    'duration': 0,
    'file': null,
    'skipped': true,
  });
  // 3) Move on to the next round
  await _advanceToNextAutoRound();
}



Future<void> _advanceToNextAutoRound() async {
  if (_currentAutoRoundIndex >= _autoDebateRounds.length - 1) {

    // All rounds done
    print("✅ Auto Debate Completed");
    _setRecording(false);
    await _stopRecording(context);
    return;
  }

  _currentAutoRoundIndex++;

 final nextRound = _autoDebateRounds[_currentAutoRoundIndex];


  // Optional delay or “Get Ready” screen
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Get ready for: ${nextRound['label']}")),
  );

  await Future.delayed(const Duration(seconds: 3)); // or show modal

  await _startAutoRound(nextRound);
}

Future<void> _startAutoRound(Map<String, dynamic> round) async {
  String label = round['label'];
  int duration = round['duration'];

  String fileName = "round_${_currentAutoRoundIndex + 1}.wav";

  _recordedRounds.add({
    'label': label,
    'duration': duration,
    'file': fileName,
  });

  setState(() {
    _currentRoundLabel = label;
    _secondsElapsed = duration;
  });

  print("🎙️ Starting auto round: $label for $duration sec as $fileName");

  await apiService.startRecording(fileName);
  _setRecording(true);

  _timer?.cancel();
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (!mounted) return;

    setState(() {
      _secondsElapsed--;
    });

    if (_secondsElapsed <= 0) {
      timer.cancel();
      await apiService.stopRecording();
      _setRecording(false);
      await _advanceToNextAutoRound();
    }
  });
}

Future<void> _resumeRecording() async {
  try {
    print("⏸️ Resume triggered... checking state");

    // ✅ First, force stop any stuck recording just in case
    await apiService.stopRecording();

    // ✅ Ask for next round label
    String nextRoundLabel = await _promptRoundLabel(context);
    String fileName = "round_${_recordedRounds.length + 1}.wav";

    _recordedRounds.add({
      'label': nextRoundLabel,
      'duration': 0,
      'file': fileName,
    });

    // ✅ Start recording now
    await apiService.startRecording(fileName);

    setState(() {
      _isPaused = false;
      _isRecording = true;
    });

    _startTimer();

    print("🎙️ Resumed recording as $fileName");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Recording resumed: $nextRoundLabel")),
      );
    }
  } catch (e) {
    print("❌ Resume failed: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error resuming recording.")),
      );
    }
  }
}

void _exitToModeSelection() {
  if (_isRecording) {
    _stopRecording(context);
  }

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
    (route) => false,
  );
}



void _startTimer() {
  _secondsElapsed = 0;
  _timer?.cancel();
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted) {
      setState(() {
        _secondsElapsed++;
      });
    }
  });
}

Future<void> _stopTimer({bool saveCurrent = true}) async {
  _timer?.cancel();

  if (saveCurrent && _secondsElapsed > 0) {
  String label = await _promptRoundLabel(context);
  String fileName = "round_${_recordedRounds.length + 1}.wav";

  _recordedRounds.add({
    'label': label,
    'duration': _secondsElapsed,
    'file': fileName,
  });
}


  _secondsElapsed = 0;
}



  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }

  void _setRecording(bool value) {
    if (mounted) {
      setState(() {
        _isRecording = value;
      });
    }
  }
Future<void> _recordAudio(BuildContext context) async {
  try {
    // ✅ Ask for initial round label
    String initialRoundLabel = await _promptRoundLabel(context);
    

    _setRecording(true);
    _isPaused = false;
    _recordedRounds.clear();

    // ✅ Generate filename for round 1
    String fileName = "round_1.wav";

    // ✅ Save round info with file name
    _recordedRounds.add({
      'label': initialRoundLabel,
      'duration': 0,
      'file': fileName, // << IMPORTANT
    });

    _startTimer();

    final response = await apiService.startRecording(fileName);

    if (mounted) {
      setState(() {
        analysisResult = response['message'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording started... Speak now!")),
      );
    }
  } catch (e) {
    _setRecording(false);
    _stopTimer(); // Save final round
    _isPaused = false;

    print("Error during recording: $e");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred while starting the recording.")),
      );
    }
  }
}
Future<void> _stopRecording(BuildContext context) async {
  // 1. stop the timer
  _timer?.cancel();

  // 2. write the elapsed seconds into the last round
  if (_recordedRounds.isNotEmpty) {
    _recordedRounds.last['duration'] = _secondsElapsed;
  }

  // 3. reset counter
  _secondsElapsed = 0;

  // 4. call backend to stop recording
  try {
    _setRecording(false);
    final response = await apiService.stopRecording();
    if (mounted) {
      setState(() {
        analysisResult = response['message'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording stopped.")),
      );
    }
  } catch (e) {
    print("Error stopping recording: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred while stopping the recording.")),
      );
    }
  }
}


  Future<String> _promptRoundLabel(BuildContext context) async {
  String label = "";
  await showDialog(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text("Label this Round"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g. Crossfire, Rebuttal..."),
        ),
        actions: [
          TextButton(
            onPressed: () {
              label = controller.text.isNotEmpty ? controller.text : "Unnamed Round";
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
  return label;
}


Future<void> _transcribeAudio(BuildContext context) async {
  String languageCode = "en";

  await showDialog(
    context: context,
    builder: (context) {
      TextEditingController langController = TextEditingController();
      return AlertDialog(
        title: const Text("Translate Transcript"),
        content: TextField(
          controller: langController,
          decoration: const InputDecoration(hintText: "e.g., en, es, hi"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              languageCode = langController.text.trim().isNotEmpty
                  ? langController.text.trim()
                  : "en";
              Navigator.of(context).pop();
            },
            child: const Text("Continue"),
          ),
        ],
      );
    },
  );

  try {
    _setLoading(true);

    String combinedTranscript = "";

    for (var round in _recordedRounds) {
      final fileName = round['file'];
      final label = round['label'];

      final transcript = await apiService.transcribeAudioFile(fileName);
      combinedTranscript += "\n[$label]\n$transcript\n";
    }

    String translated = combinedTranscript;

    if (languageCode != "en") {
      translated = await apiService.translateTranscript(combinedTranscript, languageCode);
    }

    _setLoading(false);

    if (mounted) {
      setState(() {
        analysisResult = translated;
      });

      _showResultDialog(context, "Transcript in $languageCode", combinedTranscript, translated);
    }
  } catch (e) {
    _setLoading(false);
    print("❌ Transcription error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transcription failed.")),
    );
  }
}

 Future<void> _saveAnalysisAsPDF(String text) async {
  // ── 1. Load the font file from assets
  final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);

  // ── 2. Build the PDF using that font
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.DefaultTextStyle(
        style: pw.TextStyle(font: ttf, fontSize: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("⏱ Speaking Summary:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(buildRoundSummaryText()),
            pw.SizedBox(height: 16),
            pw.Text("🧠 Analysis:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(text),
          ],
        ),
      ),
    ),
  );

  // ── 3. Save to device storage as before
  var status = await Permission.storage.request();
  if (status.isDenied || status.isPermanentlyDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Storage permission denied.")),
    );
    return;
  }
  final dir = await getExternalStorageDirectory();
  final output = File("${dir!.path}/debate_analysis_${DateTime.now().millisecondsSinceEpoch}.pdf");
  await output.writeAsBytes(await pdf.save());

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("PDF saved to: ${output.path}")),
  );

  await OpenFile.open(output.path);
}

Future<void> _analyzeDebate(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text("Lincoln-Douglas Debate"),
          onTap: () => _startAnalysis("lincoln_douglas"),
        ),
        ListTile(
          title: const Text("Policy Debate"),
          onTap: () => _startAnalysis("policy"),
        ),
        ListTile(
          title: const Text("Public Forum Debate"),
          onTap: () => _startAnalysis("public_forum"),
        ),
        ListTile(
          title: const Text("Casual Debate"), // 🆕 NEW OPTION
          onTap: () => _startAnalysis("casual"),
        ),
      ],
    ),
  );
}

//final FlutterTts _tts = FlutterTts();

Future<void> _startAutoDebate() async {
  print("🔥 Auto Debate STARTED");

  final List<DebateRound> rounds = switch (widget.format) {
  "lincoln_douglas" => lincolnDouglasRounds,
  "policy" => policyRounds,
  "public_forum" => publicForumRounds,
  _ => casualRounds,
};


  _controller = AutoDebateController(
    context: context,
    rounds: rounds,
    formatName: widget.format,
    onRoundChange: (label) {
      setState(() {
        _currentRoundLabel = label;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Round: $label")));
    },
    onTimeUpdate: (secondsLeft) {
      if (mounted) {
        setState(() {
          _secondsElapsed = secondsLeft;
        });
      }
    },
    onComplete: () {
      if (mounted) {
        _setRecording(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Auto Debate Complete")),
        );
      }
    },
  );

  _recordedRounds.clear();
  _setRecording(true);
  _isPaused = false;

  await _controller?.start();
}

/// Sends the full concatenated transcript of ALL rounds for AI analysis
Future<void> _startAnalysis(String debateType) async {
  if (_recordedRounds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Record at least one round first.")),
    );
    return;
  }

  _setLoading(true);

  // 1️⃣ Build the full transcript from every round
  String fullTranscript = "";
  for (var round in _recordedRounds) {
    final fileName = round['file'] as String;
    // transcribe each round
    final part = await apiService.transcribeAudioFile(fileName);
    fullTranscript += "\n[${round['label']}]\n$part\n";
  }

  // DEBUG: verify both speakers are present
  print("🔍 Full transcript sent to AI:\n$fullTranscript");

  // 2️⃣ Send the combined transcript text to the new endpoint
  final analysis = await apiService.analyzeDebateText(debateType, topic, fullTranscript);

  _setLoading(false);
  if (!mounted) return;

  setState(() {
    analysisResult = analysis;
  });

  // Show results (original + AI verdict)
  _showResultDialog(context, "Debate Analysis", fullTranscript, analysis);
}


void _shareAnalysis(String analysisText, String shareableLink) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("Share via Gmail"),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                "Check out this debate analysis:\n\n$analysisText\n\n🔗 $shareableLink",
                subject: "Debate Analysis from SpeakBuddy",
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Other Share Options"),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                "Check out this debate analysis:\n\n$analysisText\n\n🔗 $shareableLink",
                subject: "Debate Analysis from SpeakBuddy",
              );
            },
          ),
        ],
      );
    },
  );
}


Future<void> _showResultDialog(BuildContext context, String title, String originalText, String analysisText) async {
  if (!mounted) return;
  String shareableLink = "https://speakbuddy.app/share?analysis=${Uri.encodeComponent(analysisText)}"; // ✅ Placeholder link

String formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return "$minutes:$secs";
}

String roundSummary = "";
int total = 0;
for (var round in _recordedRounds) {
  if (round['skipped'] == true) {
    roundSummary += "${round['label']}: SKIPPED\n";
  } else {
    final int duration = round['duration'] as int;
    roundSummary += "${round['label']}: ${formatDuration(duration)}\n";
    total += duration;
  }
}
roundSummary += "\nTotal Speaking Time: ${formatDuration(total)}\n";


  Future.delayed(Duration.zero, () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 400, // ✅ Prevents overflow
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("⏱ Speaking Summary:\n$roundSummary"),
const SizedBox(height: 10),

Text("🧑‍🤝‍🧑 Speakers:\n- $speaker1\n- $speaker2"),
const SizedBox(height: 10),

Text("📌 Topic:\n$topic"),
const SizedBox(height: 10),


                Text("Original Text:\n$originalText"),
                const SizedBox(height: 10),
                Text("Result:\n$analysisText"),
                const SizedBox(height: 10),

                // ✅ Copy Text Button
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: analysisText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Text copied to clipboard!")),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy Text"),
                ),
                const SizedBox(height: 10),

                // ✅ Copy Link Button
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareableLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Link copied to clipboard!")),
                    );
                  },
                  icon: const Icon(Icons.link),
                  label: const Text("Copy Link"),
                ),
                const SizedBox(height: 10),

                // ✅ Share Analysis Button
                ElevatedButton.icon(
                  onPressed: () {
                    _shareAnalysis(analysisText, shareableLink);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text("Share Analysis"),
                ),
                // ✅ Save as PDF Button
ElevatedButton.icon(
  onPressed: () {
    _saveAnalysisAsPDF(analysisText);
  },
  icon: const Icon(Icons.save_alt),
  label: const Text("Save as PDF"),
),

              
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
  onPressed: () async {
    Navigator.pop(context); // close result dialog

    await Future.delayed(const Duration(milliseconds: 300)); // allow dialog to fully close

    final updatedInfo = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SpeakerInfoScreen(
          initialSpeaker1: speaker1,
          initialSpeaker2: speaker2,
          initialTopic: topic,
          mode: mode,
          onContinue: (s1, s2, t, f, mode) {
            Navigator.pop(_, {
              'speaker1': s1,
              'speaker2': s2,
              'topic': t,
              'format': f,
              'mode': mode,
            });
          },
        ),
      ),
    );

    if (updatedInfo != null &&
    updatedInfo['speaker1'] != null &&
    updatedInfo['speaker2'] != null &&
    updatedInfo['topic'] != null &&
    updatedInfo['format'] != null) {

final format = updatedInfo['format'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            speaker1: updatedInfo['speaker1']!,
            speaker2: updatedInfo['speaker2']!,
            topic: updatedInfo['topic']!,
            format: format!, // ✅ Add this line
            mode: mode,
          ),
        ),
      );
    }
  },
  child: const Text("Undo / Change Info"),
),

],
        
      ),
    );
  });
}





  Widget _buildCustomButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
  title: const Text('SpeakBuddy', style: TextStyle(color: Colors.white)),
  centerTitle: true,
  backgroundColor: Colors.deepPurple,
  actions: [
    IconButton(
      icon: const Icon(Icons.edit_note, color: Colors.white),
      tooltip: "Edit Speaker Info",
      onPressed: () async {
        if (_isRecording) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Change"),
              content: const Text("You’ll lose your current recording. Are you sure?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
              ],
            ),
          );
          if (confirm != true) return;
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, _, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            pageBuilder: (_, __, ___) => SpeakerInfoScreen(
              initialSpeaker1: speaker1,
              initialSpeaker2: speaker2,
              initialTopic: topic,
              mode: mode,
              onContinue: (s1, s2, t, f, mode) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(speaker1: s1, speaker2: s2, topic: t, format: f, mode: mode),
                  ),
                );
              },
            ),
          ),
        );
      },
    )
  ],
),

          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    const Text(
      "🧠 Current Debate Info",
      style: TextStyle(fontSize: 18, color: Colors.white),
    ),
    Text("• $speaker1 vs $speaker2", style: const TextStyle(color: Colors.white70)),
    Text("• Topic: $topic", style: const TextStyle(color: Colors.white70)),
    const SizedBox(height: 20),
  ],
),
if (!_isRecording && mode == "normal")
  _buildCustomButton(context, "🎙️ Start Recording", Colors.orangeAccent, () => _recordAudio(context)),

if (!_isRecording && mode == "auto")
  _buildCustomButton(context, "🎙️ Begin Auto Debate", Colors.deepPurpleAccent, _startAutoDebate),

if (_isRecording) ...[
  const SizedBox(height: 20),

  if (mode == "normal" && !_isPaused)
    _buildCustomButton(context, "⏸️ Pause Recording", Colors.amber, _pauseRecording),

  if (mode == "normal" && _isPaused)
    _buildCustomButton(context, "▶️ Resume Recording", Colors.green, _resumeRecording),

  if (mode == "normal")
    _buildCustomButton(context, "⏹️ Stop Recording", Colors.redAccent, () => _stopRecording(context)),

  if (mode == "auto")
    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _buildCustomButton(context, "⏭️ Skip Round", Colors.orangeAccent, _skipCurrentAutoRound),
    const SizedBox(width: 16),
    _buildCustomButton(context, "✅ Finish Round Early", Colors.green, _endCurrentAutoRound),
  ],
),

],

                  const SizedBox(height: 20),
                  _buildCustomButton(context, "📝 Transcribe Audio", Colors.lightBlueAccent, () => _transcribeAudio(context)),
                  const SizedBox(height: 20),
                  _buildCustomButton(context, "⚖️ Analyze Debate", Colors.greenAccent, () => _analyzeDebate(context)),
                  const SizedBox(height: 20),
                  _buildCustomButton(context, "❌ End Debate & Return", Colors.grey, _exitToModeSelection),


                ],
              ),
            ),
          ),
        ),
        
        // ⏱️ TIMER OVERLAY HERE
if (_isRecording)
  Positioned(
    top: mode == "auto" ? 70 : 20,
    right: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // TIMER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formattedTime,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // LABEL (only show if set)
        if (_currentRoundLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentRoundLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ],
    ),
  ),

if (mode == "auto")
  Positioned(
    // ↓ push below status bar + AppBar
    top: MediaQuery.of(context).padding.top + kToolbarHeight,
    left: 0,
    right: 0,
    child: Container(
      color: Colors.deepPurple.shade900,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Center(
        child: Text(
          "🤖 Auto Debate Mode Active – Manual Controls Disabled",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ),
  ),


        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 6,
              ),
            ),
          ),
      ],
    );
  }
}
