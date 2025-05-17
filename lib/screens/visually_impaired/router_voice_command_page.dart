import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'stt_command_page.dart';
import 'text_to_speech_page.dart';

class RouterVoiceCommandPage extends StatefulWidget {
  const RouterVoiceCommandPage({Key? key}) : super(key: key);

  @override
  State<RouterVoiceCommandPage> createState() => _RouterVoiceCommandPageState();
}

class _RouterVoiceCommandPageState extends State<RouterVoiceCommandPage> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  bool _isSpeaking = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);

    await Permission.microphone.request();
    await _speak("Welcome. Say 'speech to text' or 'text to speech' to begin.");
    await _listen();
  }

  Future<void> _speak(String message) async {
    _isSpeaking = true;
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    await _tts.speak(message);
    await _tts.awaitSpeakCompletion(true);
    _isSpeaking = false;
  }

  Future<void> _listen() async {
    bool available = await _speech.initialize();
    if (!available) return;

    while (mounted) {
      String command = '';

      print("[Router] Listening for command...");
      await _speech.listen(
        onResult: (result) {
          command = result.recognizedWords.toLowerCase().trim();
          print("[Router] Heard: $command");
        },
        pauseFor: const Duration(seconds: 3),
        listenMode: ListenMode.confirmation,
        partialResults: false,
        localeId: 'en_US',
      );

      await Future.delayed(const Duration(seconds: 5));
      await _speech.stop();

      if (command.contains("speech to text") || command.contains("start stt")) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const STTCommandPage()),
        );
        return; // çık
      } else if (command.contains("text to speech") || command.contains("start tts")) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TextToSpeechPage()),
        );
        return; // çık
      } else {
        await _speak("Command not recognized. Please say 'speech to text' or 'text to speech'.");
        // döngü devam edecek, tekrar dinlenecek
      }
    }
  }


  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36EEE0),
      appBar: AppBar(
        title: const Text('Choose Mode'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          'Say "speech to text" or "text to speech"',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
