class GradingService {
  String evaluateSpeech(String transcription) {
    final words = transcription.split(' ').length;
    if (words > 100) {
      return "Grade: Excellent";
    } else if (words > 50) {
      return "Grade: Good";
    } else {
      return "Grade: Needs Improvement";
    }
  }
}
