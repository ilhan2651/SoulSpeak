import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clipboard/clipboard.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../services/stt_service.dart';

class STTCommandPage extends StatefulWidget {
  const STTCommandPage({Key? key}) : super(key: key);

  @override
  State<STTCommandPage> createState() => _STTCommandPageState();
}

class _STTCommandPageState extends State<STTCommandPage> {
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speech = SpeechToText();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordedFilePath;
  String _debugText = '';
  String? _recognizedText;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);

    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      await _speakSafe("Microphone permission is required.");
      return;
    }

    await _repeatInstructions();
  }

  Future<void> _speakSafe(String text) async {
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      print("TTS error: $e");
    }
  }

  Future<void> _repeatInstructions() async {
    await _speakSafe("Long press to start recording.");
    await _speakSafe("Long press again to stop and choose an action.");
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _recordedFilePath = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, bitRate: 128000, sampleRate: 16000),
      path: _recordedFilePath!,
    );

    setState(() {
      _isRecording = true;
      _debugText = '🎙️ Recording started: $_recordedFilePath';
    });

    await _speakSafe("Recording started. You can speak now.");
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    _isProcessing = true;

    await _speakSafe("Recording stopped.");
    await _speakSafe("Sending to server.");

    if (path != null && File(path).existsSync()) {
      final file = File(path);
      final fileSize = await file.length();

      setState(() => _debugText = 'Recorded file size: $fileSize bytes');

      if (fileSize < 4000) {
        await _speakSafe("The recording was too short. Please try again.");
        _isProcessing = false;
        return;
      }

      final result = await STTService().analyzeAudio(file);
      final text = result?['text'] ?? 'Could not understand.';

      setState(() {
        _recognizedText = text;
        _debugText = '📝 Text: $text';
      });

      await _speakSafe("Analysis complete.");

      final txtFile = await _saveTextFile(text);

      await _speakSafe("What do you want to do with the result?");
      await _speakSafe("Say share, save or copy.");

      final action = await _listenForCommand();

      if (action == "share") {
        await Share.shareXFiles([XFile(txtFile.path)], text: "Here is the recognized text.");
        await _speakSafe("Text shared.");
      } else if (action == "copy") {
        await FlutterClipboard.copy(text);
        await _speakSafe("Text copied to clipboard.");
      } else if (action == "save") {
        await _speakSafe("Text saved.");
      } else {
        await _speakSafe("No valid command detected.");
        _isProcessing = false;
        return;
      }

      _isProcessing = false;
      await _repeatInstructions();
    } else {
      await _speakSafe("No valid recording found.");
      _isProcessing = false;
      await _repeatInstructions();
    }
  }

  Future<File> _saveTextFile(String text) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/recognized_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(text);
    return file;
  }

  Future<String?> _listenForCommand() async {
    bool available = await _speech.initialize();
    if (!available) return null;

    String command = '';

    while (command.isEmpty) {
      await _speech.listen(
        onResult: (result) {
          command = result.recognizedWords.toLowerCase().trim();
        },
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        localeId: 'en_US',
      );

      await Future.delayed(const Duration(seconds: 5));
      await _speech.stop();

      if (command.isEmpty) {
        await _speakSafe("I didn’t hear anything. Listening again.");
      }
    }

    if (command.contains("share")) return "share";
    if (command.contains("save")) return "save";
    if (command.contains("copy")) return "copy";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36EEE0),
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        backgroundColor: Colors.teal,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () async {
          if (_isProcessing) return;

          if (_isRecording) {
            await _stopRecording();
          } else {
            await _startRecording();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRecording
                    ? '🎙️ Recording... Long press to stop.'
                    : '▶️ Long press to start recording.',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                _debugText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
