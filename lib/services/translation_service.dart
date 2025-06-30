import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // File selection

class TranscriptionScreen extends StatefulWidget {
  @override
  _TranscriptionScreenState createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final TranslationService translationService = TranslationService();
  String transcriptionText = "Transcribed text will appear here...";
  String translationText = "Translated text will appear here...";
  final TextEditingController languageController = TextEditingController();

  /// Picks an audio file, checks size, and transcribes it
  Future<void> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      double fileSizeMB = (result.files.single.size / (1024 * 1024)); // Convert bytes to MB

      if (fileSizeMB > 1.0) { // 1MB file size limit
        setState(() {
          transcriptionText = "⚠️ Error: File is too large (over 1MB). Please upload a smaller file.";
        });
        return;
      }

      transcribeAudio(result.files.single.path ?? "");
    }
  }

  /// Simulates transcription (replace with actual Whisper API if available)
  Future<void> transcribeAudio(String audioFilePath) async {
    setState(() {
      transcriptionText = "Processing transcription...";
      translationText = "Waiting for translation...";
    });

    try {
      await Future.delayed(Duration(seconds: 2)); // Simulated delay
      setState(() {
        transcriptionText = "This is a sample transcription from the audio file. " * 50; // Long text for testing
      });
    } catch (e) {
      setState(() {
        transcriptionText = "Error during transcription.";
      });
    }
  }

  /// Calls `TranslationService` to translate text
  Future<void> translateText() async {
    if (transcriptionText.isNotEmpty && languageController.text.isNotEmpty) {
      setState(() {
        translationText = "Translating...";
      });

      String translatedText = await translationService.translateText(
        transcriptionText,
        languageController.text.trim(),
      );

      setState(() {
        translationText = translatedText;
      });
    } else {
      setState(() {
        translationText = "Please enter a valid language code.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transcription & Translation")),
      body: Column(
        children: [
          // Transcription Section
          Flexible(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.cyan[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transcription", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            return Text(
                              transcriptionText,
                              style: TextStyle(fontSize: 16),
                              softWrap: true,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    onPressed: pickAudioFile,
                    child: Text("Select Audio File"),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 2, color: Colors.black54),

          // Language Input & Translate Button
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: languageController,
                    decoration: InputDecoration(
                      hintText: "Enter language code (e.g., en, es)",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: translateText,
                  child: Text("Translate"),
                ),
              ],
            ),
          ),

          // Translation Section
          Flexible(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.red[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Translation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            return Text(
                              translationText,
                              style: TextStyle(fontSize: 16),
                              softWrap: true,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: translationText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Translated text copied to clipboard!")),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy Translation"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Translation Service**
class TranslationService {
  final Dio _dio = Dio();
  final String apiKey = "sk-proj-YOUR-OPENAI-API-KEY"; // Replace with your OpenAI API key

  Future<String> translateText(String text, String targetLanguage) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "You are a translation assistant. Translate the text into $targetLanguage."
            },
            {"role": "user", "content": text}
          ]
        },
      );

      return response.data['choices'][0]['message']['content'].toString();
    } catch (e) {
      print("Translation Error: $e");
      return "Error during translation";
    }
  }
}
