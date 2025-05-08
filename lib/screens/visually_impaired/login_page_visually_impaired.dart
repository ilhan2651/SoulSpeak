import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:soulspeakma/screens/visually_impaired/stt_command_page.dart' show STTCommandPage;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

import '../../services/api.dart'; // Api.login vs Api.getProfile vs Api.register

class LoginPageVisuallyImpaired extends StatefulWidget {
  const LoginPageVisuallyImpaired({super.key});

  @override
  State<LoginPageVisuallyImpaired> createState() => _LoginPageVisuallyImpairedState();
}

class _LoginPageVisuallyImpairedState extends State<LoginPageVisuallyImpaired> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late FlutterTts _tts;
  late stt.SpeechToText _stt;
  Timer? _reminderTimer;

  String _currentStep = "email";
  String _tempInput = "";
  bool _awaitingConfirmation = false;
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _stt = stt.SpeechToText();
    _setupTTS();
    _startLogin();
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    _reminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _setupTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.35);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _speak(String text) async {
    print("TTS ➜ $text");
    await _tts.stop();
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _startLogin() async {
    await _speak("Welcome. Please say your email address.");
    _listen();
  }

  void _listen() async {
    bool available = await _stt.initialize(
      onStatus: (status) => print("STT Status: $status"),
      onError:  (e)      => print("STT Error: $e"),
    );
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    _stt.listen(
      listenFor: const Duration(seconds: 60),
      pauseFor:  const Duration(seconds: 10),
      onResult: (result) {
        print("Recognized: ${result.recognizedWords}");
        if (result.finalResult) {
          _processSpeech(result.recognizedWords.trim());
        }
      },
    );
    // sessizlik hatırlatması
    _reminderTimer?.cancel();
    _reminderTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _speak(_prompt()).then((_) {
        if (mounted) _listen();
      });
    });
  }

  String _prompt() {
    switch (_currentStep) {
      case "email":
        return "Please say your email address.";
      case "password":
        return "Please say your password.";
      default:
        return "";
    }
  }

  void _processSpeech(String speech) {
    print("🛠 _processSpeech step=$_currentStep, awaiting=$_awaitingConfirmation, input='$speech'");
    _reminderTimer?.cancel();
    if (!_awaitingConfirmation) {
      _tempInput = speech;
      _speak("You said $_tempInput. Say yes to confirm or repeat.").then((_) {
        _awaitingConfirmation = true;
        if (mounted) _listen();
      });
    } else {
      final lower = speech.toLowerCase();
      if (lower.contains("yes")) {
        final normalized = _normalize(_tempInput, _currentStep);
        if (_currentStep == "email") {
          _emailController.text = normalized;
          _currentStep = "password";
          _awaitingConfirmation = false;
          _speak("Email confirmed. Now say your password.").then((_) {
            if (mounted) _listen();
          });
        } else {
          // password adımı onaylandı → direkt login yap
          _passwordController.text = normalized;
          _awaitingConfirmation = false;
          _attemptLogin();
        }
      } else if (lower.contains("repeat")) {
        _awaitingConfirmation = false;
        _speak("Let's try again. " + _prompt()).then((_) {
          if (mounted) _listen();
        });
      } else {
        _speak("Say yes to confirm or repeat.").then((_) {
          if (mounted) _listen();
        });
      }
    }
  }

  String _normalize(String input, String step) {
    input = input.toLowerCase();
    Map<String,String> map = {
      'zero':'0','one':'1','two':'2','three':'3','four':'4','five':'5',
      'six':'6','seven':'7','eight':'8','nine':'9',
      'dot':'.','at':'@','et':'@','comma':',','dash':'-','hyphen':'-',
      'underscore':'_','question mark':'?','space':''
    };
    map.forEach((k,v){ input=input.replaceAll(k,v); });
    if (['email','password'].contains(step)) {
      input = input.replaceAll(' ', '');
    }
    return input;
  }

  Future<void> _attemptLogin() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _speak("Logging in, please wait.");
    try {
      final resp = await http.post(
        Uri.parse(Api.login),
        headers: {"Content-Type":"application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text
        }),
      );
      print("🔌 HTTP ${resp.statusCode} ${resp.body}");
      if (resp.statusCode == 200) {
        await _speak("Login successful. Redirecting.");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const STTCommandPage()),
        );
      } else {
        final data = jsonDecode(resp.body);
        final msg = data["title"] ??
            (data["errors"] != null
                ? data["errors"].values.map((v)=>v.join(",")).join(". ")
                : "Login failed.");
        await _speak(msg);
        _restartLogin();
      }
    } catch (e) {
      print("⚠️ Login exception: $e");
      await _speak("An error occurred. Please try again.");
      _restartLogin();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _restartLogin() {
    if (!mounted) return;
    _currentStep = "email";
    _emailController.clear();
    _passwordController.clear();
    _awaitingConfirmation = false;
    _speak("Let's start over. Please say your email address.").then((_) {
      if (mounted) _listen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36EEE0),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text(
          "Voice Login Page",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
