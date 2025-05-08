import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TestTTS extends StatefulWidget {
  @override
  _TestTTSState createState() => _TestTTSState();
}

class _TestTTSState extends State<TestTTS> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _configureTTS();
  }

  Future<void> _configureTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0); // Maksimum ses seviyesi
    await _tts.setPitch(1.0);
  }

  Future<void> _speak() async {
    print("🔊 Speaking started...");
    var result = await _tts.speak("Hello! This is a test for Text-to-Speech.");
    print("✅ Speak result: $result");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("TTS Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: _speak,
          child: Text("Test TTS"),
        ),
      ),
    );
  }
}
