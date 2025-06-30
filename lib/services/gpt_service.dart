import 'package:dio/dio.dart';

class GPTService {
  final Dio _dio = Dio();
  static const String baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String model = "gpt-4";

  Future<String> analyzeText(String text) async {
    try {
      final response = await _dio.post(
        baseUrl,
        data: {
          "model": model,
          "messages": [
            {"role": "system", "content": "You are an AI trained in debate analysis."},
            {"role": "user", "content": "Analyze this debate transcript and provide key insights: $text"}
          ],
          "max_tokens": 200,
        },
        options: Options(headers: {
          'Authorization': 'Bearer YOUR_OPENAI_API_KEY',
          'Content-Type': 'application/json'
        }),
      );
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      print(e);
      return "Error during analysis";
    }
  }

  Future<String> summarizeText(String text) async {
    try {
      final response = await _dio.post(
        baseUrl,
        data: {
          "model": model,
          "messages": [
            {"role": "system", "content": "You are an AI trained in summarization."},
            {"role": "user", "content": "Summarize this text: $text"}
          ],
          "max_tokens": 100,
        },
        options: Options(headers: {
          'Authorization': 'Bearer YOUR_OPENAI_API_KEY',
          'Content-Type': 'application/json'
        }),
      );
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      print(e);
      return "Error during summarization";
    }
  }
}
