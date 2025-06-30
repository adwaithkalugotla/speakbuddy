import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://172.20.10.2:5000"; // Flask backend URL

 Future<Map<String, dynamic>> startRecording(String fileName) async {
  print("📡 Calling Flask API to start recording: $fileName");
  final response = await http.post(
    Uri.parse("$baseUrl/record_audio"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "file_name": fileName, // ✅ Pass custom filename
    }),
  );


  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to start recording");
  }
}


  Future<Map<String, dynamic>> stopRecording() async {
    final response = await http.post(
      Uri.parse("$baseUrl/stop_recording"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to stop recording");
    }
  }

  Future<String> transcribeAudio() async {
    final response = await http.get(Uri.parse("$baseUrl/transcribe"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['transcript'];
    } else {
      throw Exception("Failed to transcribe audio");
    }
  }

Future<String> transcribeAudioFile(String fileName) async {
  final response = await http.post(
    Uri.parse("$baseUrl/transcribe"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"file_name": fileName}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['transcript'];
  } else {
    throw Exception("Failed to transcribe audio file");
  }
}

Future<String> analyzeDebate(String debateType, String topic, String fileName) async {
  final response = await http.post(
    Uri.parse("$baseUrl/analyze"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "debate_type": debateType,
      "topic": topic,
      "file_name": fileName,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['analysis'] != null) {
      return data['analysis'];
    } else {
      print("❌ No 'analysis' found in backend response: $data");
      throw Exception("Backend response missing 'analysis'.");
    }
  } else {
    print("❌ Backend returned ${response.statusCode}: ${response.body}");
    throw Exception("Failed to analyze debate");
  }
}

/// Sends a raw text transcript (all rounds) instead of a filename
Future<String> analyzeDebateText(String debateType, String topic, String transcript) async {
  final response = await http.post(
    Uri.parse("$baseUrl/analyze_text"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "debate_type": debateType,
      "topic": topic,
      "transcript": transcript,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['analysis'];
  } else {
    throw Exception("Failed to analyze debate text: ${response.body}");
  }
}


Future<String> translateTranscript(String text, String targetLanguage) async {
  final response = await http.post(
    Uri.parse("$baseUrl/translate"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "text": text,
      "target_language": targetLanguage,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['translated'] ?? text;
  } else {
    throw Exception("Translation failed: ${response.body}");
  }
}



}
