import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../services/tts_service.dart';

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({Key? key}) : super(key: key);

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TTSService _ttsService = TTSService();
  final SpeechToText _speech = SpeechToText();

  bool _isProcessing = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  Future<void> _startLoop() async {
    await _speakSafe("Welcome. Say 'file' or 'clipboard' to choose the source of the text.");
    while (mounted) {
      await _listenForCommand();
    }
  }

  Future<void> _speakSafe(String text) async {
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  Future<void> _listenForCommand() async {
    await Future.delayed(const Duration(seconds: 1));
    await _speakSafe("Do you want to read a file or clipboard text?");
    final command = await _getVoiceCommand();

    if (command.contains("file")) {
      await _speakSafe("File selected.");
      await _handleFileInput();
    } else if (command.contains("clipboard")) {
      await _speakSafe("Clipboard selected.");
      await _handleClipboardInput();
    } else {
      await _speakSafe("Command not recognized. Please say file or clipboard.");
    }
  }

  Future<String> _getVoiceCommand() async {
    bool available = await _speech.initialize();
    if (!available) return '';

    String resultText = '';

    while (resultText.isEmpty && mounted) {
      await _speech.listen(
        onResult: (result) {
          resultText = result.recognizedWords.toLowerCase().trim();
        },
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        localeId: 'en_US',
      );

      await Future.delayed(const Duration(seconds: 5));
      await _speech.stop();

      if (resultText.isEmpty) {
        await _speakSafe("I didn’t hear anything. Listening again.");
      }
    }

    return resultText;
  }

  Future<void> _handleFileInput() async {
    final result = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: 'text', extensions: ['txt'])],
    );

    if (result != null) {
      final file = File(result.path);
      final text = await file.readAsString();
      await _convertAndPlay(text);
    } else {
      await _speakSafe("No file selected.");
    }
  }

  Future<void> _handleClipboardInput() async {
    final text = await FlutterClipboard.paste();
    if (text.trim().isEmpty) {
      await _speakSafe("Clipboard is empty.");
    } else {
      await _convertAndPlay(text);
    }
  }

  Future<void> _convertAndPlay(String text) async {
    setState(() {
      _isProcessing = true;
      _status = 'Generating voice...';
    });

    final path = await _ttsService.convertTextToSpeech(text);

    if (path != null && File(path).existsSync()) {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
      await _speakSafe("Reading completed. Say file or clipboard to continue.");
    } else {
      await _speakSafe("Failed to generate voice.");
    }

    setState(() {
      _isProcessing = false;
      _status = '';
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36EEE0),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Text to Speech (for Visually Impaired)"),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ],
        )
            : const Text(
          "Awaiting voice command...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
