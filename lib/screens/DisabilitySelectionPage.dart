import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/registration_page.dart';
import 'package:soulspeakma/screens/visually_impaired/registratrion_page_visually_impaired.dart';

class DisabilitySelectionPage extends StatefulWidget {
  @override
  _DisabilitySelectionPageState createState() => _DisabilitySelectionPageState();
}

class _DisabilitySelectionPageState extends State<DisabilitySelectionPage> {
  FlutterTts _tts = FlutterTts();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _configureTTS();
    _delayedVoiceGuidance();
  }

  Future<void> _configureTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
    print("✅ TTS Configured!");
  }

  void _delayedVoiceGuidance() {
    Future.delayed(Duration(seconds: 1), () {
      _speak(
          "Welcome! Tap the top half for Visually Impaired mode or bottom half for Hard Hearing Impaired mode.");

    });

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _speak(
          "If you haven't selected yet, tap the top half for Visually Impaired mode or the bottom half for Hard Hearing Impaired mode.");
    });
  }

  Future<void> _speak(String text) async {
    await _tts.stop(); // Stop previous speech
    await _tts.speak(text);
  }

  Future<void> _selectDisability(String type) async {
    _timer?.cancel();

    String confirmationMessage = type == "VisuallyImpaired"
        ? "Visually Impaired Mode selected. Redirecting to VP Registration Page."
        : "Hard Hearing Impaired Mode selected. Redirecting to Registration Page.";

    _speak(confirmationMessage);

    Future.delayed(Duration(seconds: 2), () {
      if (type == "VisuallyImpaired") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationPageVisuallyImpaired()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationPage()),
        );
      }
    });
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF36EEE0),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    print("📌 Visually Impaired Mode Selected.");
                    _speak("Visually Impaired Mode selected.");
                    _selectDisability("VisuallyImpaired");
                  },
                  child: Semantics(
                    label: "Tap the top half for Visually Impaired mode.",
                    child: Container(
                      color: Colors.transparent, // Invisible touch area
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              Center(
                child: Semantics(
                  label: "Application Logo. Non-clickable.",
                  child: Image.asset(
                    "assets/images/33.png",
                    width: 250,
                    height: 250,
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    print("📌 Hard Hearing Impaired Mode Selected.");
                    _speak("Hard Hearing Impaired Mode selected.");
                    _selectDisability("HardHearingImpaired");
                  },
                  child: Semantics(
                    label: "Tap the bottom half for Hard Hearing Impaired mode.",
                    child: Container(
                      color: Colors.transparent, // Invisible touch area
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Semantics(
                label:
                "Tap the top half for Visually Impaired mode, or the bottom half for Hard Hearing Impaired mode.",
                child: Text(
                  "Tap the top half for Visually Impaired mode, or the bottom half for Hard Hearing Impaired mode.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
