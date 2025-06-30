import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../models/round_models.dart';

class AutoDebateController {
  final BuildContext context;
  final List<DebateRound> rounds;
  final String formatName;
  final Function(String roundLabel) onRoundChange;
  final Function(int secondsLeft) onTimeUpdate;
  final Function() onComplete;

 // final FlutterTts _tts = FlutterTts();
  final ApiService _apiService = ApiService();

  int _currentRoundIndex = 0;
  Timer? _timer;
  bool _isRunning = false;

  AutoDebateController({
    required this.context,
    required this.rounds,
    required this.formatName,
    required this.onRoundChange,
    required this.onTimeUpdate,
    required this.onComplete,
  });

  Future<void> start() async {
    _isRunning = true;
    _currentRoundIndex = 0;
    await _runNextRound();
  }

  Future<void> _runNextRound() async {
    if (_currentRoundIndex >= rounds.length) {
     // await _tts.speak("Debate complete. Thank you for participating.");
      onComplete();
      return;
    }

    final round = rounds[_currentRoundIndex];
    onRoundChange(round.label);

   // await _tts.speak("Next round: ${round.label}. You will have ${round.durationSeconds ~/ 60} minutes.");
    await Future.delayed(const Duration(seconds: 4));

    String filename = "${formatName}_round_${_currentRoundIndex + 1}.wav";
    await _apiService.startRecording(filename);

    int secondsLeft = round.durationSeconds;
    onTimeUpdate(secondsLeft);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isRunning) return;

      secondsLeft--;
      onTimeUpdate(secondsLeft);

      if (secondsLeft <= 0) {
        timer.cancel();
        await _apiService.stopRecording();
        _currentRoundIndex++;
       // await _tts.speak("Time's up.");
        await Future.delayed(const Duration(seconds: 2));
        await _runNextRound();
      }
    });
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
  }
}
