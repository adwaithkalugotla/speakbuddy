import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class AudioRecorder extends StatefulWidget {
  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  /// **Initialize the recorder & request permissions**
  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();

    // Request microphone permissions
    await Permission.microphone.request();

    if (await Permission.microphone.isGranted) {
      try {
        await _recorder!.openRecorder();
        _recorder!.setSubscriptionDuration(const Duration(milliseconds: 500));
      } catch (e) {
        print("Error initializing recorder: $e");
      }
    } else {
      print("Microphone permission denied");
    }
  }

  /// **Start recording**
  Future<void> _startRecording() async {
    if (_recorder == null) return;

    try {
      Directory tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/audio_record.wav';

      await _recorder!.startRecorder(toFile: _filePath);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  /// **Stop recording**
  Future<void> _stopRecording() async {
    if (_recorder == null) return;

    try {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      print("Recording saved to: $_filePath");
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Audio Recorder")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? "Stop Recording" : "Start Recording"),
            ),
            if (_filePath != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("Saved file: $_filePath"),
              ),
          ],
        ),
      ),
    );
  }
}
