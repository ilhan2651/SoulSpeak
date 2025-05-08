import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soulspeakma/services/stt_service.dart' show STTService;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:clipboard/clipboard.dart';
import 'package:share_plus/share_plus.dart';

class STTCommandPage extends StatefulWidget {
  const STTCommandPage({super.key});

  @override
  State<STTCommandPage> createState() => _STTCommandPageState();
}

class _STTCommandPageState extends State<STTCommandPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isListening = false;
  String _recognizedCommand = "";
  String _resultText = "";

  @override
  void initState() {
    super.initState();
    // ✅ async işlemleri düzgün başlatmak için microtask kullandık
    Future.microtask(() async {
      await _initRecorder();
      await _speak("Say start to begin recording. Say stop to stop and analyze.");
    });
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    await _speech.listen(onResult: (result) {
      setState(() {
        _recognizedCommand = result.recognizedWords.toLowerCase();
      });
      if (_recognizedCommand.contains("start")) {
        _speak("Recording started");
        _startRecording();
      } else if (_recognizedCommand.contains("stop")) {
        _speak("Recording stopped and analyzing");
        _stopRecordingAndAnalyze();
      }
    });
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    String path = "${dir.path}/temp_audio.wav";
    await _recorder.startRecorder(toFile: path);
  }

  Future<void> _stopRecordingAndAnalyze() async {
    final path = await _recorder.stopRecorder();
    if (path == null) return;
    final file = File(path);
    final result = await STTService().analyzeAudio(file);
    if (result != null && result["text"] != null) {
      setState(() {
        _resultText = result["text"];
      });
      _speak(_resultText);
    } else {
      _speak("Sorry, could not understand.");
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36EEE0),
      appBar: AppBar(
        title: const Text("Voice Assistant"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Recognized Command: $_recognizedCommand", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text("Result Text:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_resultText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? "Stop Listening" : "Start Listening"),
            ),
            const SizedBox(height: 10),
            if (_resultText.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy"),
                    onPressed: () {
                      FlutterClipboard.copy(_resultText);
                      _speak("Copied to clipboard");
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                    onPressed: () {
                      Share.share(_resultText);
                    },
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
