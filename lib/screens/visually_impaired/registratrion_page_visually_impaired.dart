import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:soulspeakma/screens/visually_impaired/login_page_visually_impaired.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';

class RegistrationPageVisuallyImpaired extends StatefulWidget {
  const RegistrationPageVisuallyImpaired({super.key});

  @override
  State<RegistrationPageVisuallyImpaired> createState() =>
      _RegistrationPageVisuallyImpairedState();
}

class _RegistrationPageVisuallyImpairedState
    extends State<RegistrationPageVisuallyImpaired> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late FlutterTts _tts;
  late stt.SpeechToText _stt;

  bool _isListening = false;
  bool _isLoading = false;
  String _errorMessage = "";

  String _currentStep = "choice";
  String _tempInput = "";
  bool _awaitingConfirmation = false;
  final String _selectedDisability = "Visually Impaired";

  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _stt = stt.SpeechToText();
    _configureTTS();
    _startInitialPrompt();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    _reminderTimer?.cancel();
    _stt.stop();
    _tts.stop();
  }

  Future<void> _configureTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.35);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _speak(String text) async {
    print('TTS: $text');
    if (!mounted) return;
    await _tts.stop();
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _startInitialPrompt() async {
    await _speak(
      "If you are already registered, say login. Otherwise, say continue to begin registration.",
    );
    if (!mounted) return;
    _listen();
  }

  void _listen() async {
    bool available = await _stt.initialize(
      onStatus: (status) {
        print('STT Status: $status');
        if (status == 'notListening' && mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _listen();
          });
        }
      },
      onError: (error) {
        print('STT Error: $error');
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _listen();
          });
        }
      },
    );
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    _stt.listen(
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      onResult: (result) {
        print('Recognized: ${result.recognizedWords}');
        if (result.finalResult) {
          _processSpeech(result.recognizedWords.trim());
        }
      },
    );
    _startReminder();
  }

  void _startReminder() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _speak(_getPrompt()).then((_) {
        if (mounted) _listen();
      });
    });
  }

  String _getPrompt() {
    switch (_currentStep) {
      case 'name':
        return 'Please say your full name.';
      case 'email':
        return 'Please say your email address.';
      case 'password':
        return 'Please say your password.';
      case 'confirmPassword':
        return 'Please say your password again to confirm.';
      case 'confirm':
        return 'Do you want to confirm? If yes, say yes. If not, say repeat.';
      default:
        return '';
    }
  }

  void _processSpeech(String speech) {
    print('ProcessSpeech step=$_currentStep, awaitingConfirmation=$_awaitingConfirmation, input="$speech"');
    if (!mounted) return;
    _reminderTimer?.cancel();

    if (_currentStep == 'choice') {
      String lower = speech.toLowerCase();
      if (lower.contains('login')) {
        _cleanup();
        _speak('Redirecting to login page.').then((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPageVisuallyImpaired(),
            ),
          );
        });
      } else if (lower.contains('continue')) {
        _currentStep = 'name';
        _speak('Let\'s begin registration. Please say your full name.').then((_) {
          if (mounted) _listen();
        });
      } else {
        _speak('I did not understand. Say login or continue.').then((_) {
          if (mounted) _listen();
        });
      }
      return;
    }

    if (!_awaitingConfirmation) {
      _tempInput = speech;
      if (_tempInput.isEmpty) {
        _speak(_getPrompt());
        return;
      }
      _speak('You said: $_tempInput. Say yes to confirm or repeat.').then((_) {
        if (mounted) _listen();
        _awaitingConfirmation = true;
      });
    } else {
      String lower = speech.toLowerCase();
      if (lower.contains('yes')) {
        String normalized = _normalize(_tempInput, _currentStep);
        switch (_currentStep) {
          case 'name':
            _nameController.text = normalized;
            _currentStep = 'email';
            _awaitingConfirmation = false;
            _speak('Name confirmed. Now say your email address.').then((_) {
              if (mounted) _listen();
            });
            break;
          case 'email':
            _emailController.text = normalized;
            _currentStep = 'password';
            _awaitingConfirmation = false;
            _speak('Email confirmed. Now say your password.').then((_) {
              if (mounted) _listen();
            });
            break;
          case 'password':
            _passwordController.text = normalized;
            _currentStep = 'confirmPassword';
            _awaitingConfirmation = false;
            _speak('Password confirmed. Now repeat your password.').then((_) {
              if (mounted) _listen();
            });
            break;
          case 'confirmPassword':
            _confirmPasswordController.text = normalized;
            _currentStep = 'confirm';
            _awaitingConfirmation = false;
            _speak('All details collected. Say yes to confirm or repeat.').then((_) {
              if (mounted) _listen();
            });
            break;
          case 'confirm':
          // Check mismatch here, redirect to name
            if (_passwordController.text != _confirmPasswordController.text) {
              print('Password mismatch: ${_passwordController.text} != ${_confirmPasswordController.text}');
              _speak('Passwords do not match. Restarting registration.').then((_) {
                _resetRegistration();
              });
            } else {
              _registerUser();
            }
            break;
        }
      } else if (lower.contains('repeat')) {
        _awaitingConfirmation = false;
        _speak('Let\'s try again. ' + _getPrompt()).then((_) {
          if (mounted) _listen();
        });
      } else {
        _speak('Say yes to confirm or repeat.').then((_) {
          if (mounted) _listen();
        });
      }
    }
  }

  String _normalize(String input, String step) {
    input = input.toLowerCase();
    Map<String, String> map = {
      'zero': '0', 'one': '1', 'two': '2', 'three': '3',
      'four': '4', 'five': '5', 'six': '6',
      'seven': '7', 'eight': '8', 'nine': '9',
      'dot': '.', 'at': '@', 'et': '@', 'comma': ',', 'dash': '-', 'hyphen': '-',
      'underscore': '_', 'question mark': '?', 'space': ''
    };
    map.forEach((k, v) => input = input.replaceAll(k, v));
    if (['email', 'password', 'confirmPassword'].contains(step)) {
      input = input.replaceAll(' ', '');
    }
    return input;
  }

  Future<void> _registerUser() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    print('Attempting registration: ' +
        'Name=$_nameController.text, ' +
        'Email=$_emailController.text');
    final success = await AuthService().registerUser(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _confirmPasswordController.text,
      _selectedDisability,
    );
    setState(() => _isLoading = false);
    if (success) {
      print('Registration successful');
      _speak('Registration successful. Redirecting to login page.')
          .then((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPageVisuallyImpaired(),
            ),
          );
        }
      });
    } else {
      print('Registration failed');
      _speak('Registration failed. Restarting the process.').then((_) {
        _resetRegistration();
      });
    }
  }

  void _resetRegistration() {
    if (!mounted) return;
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _currentStep = 'name';
      _awaitingConfirmation = false;
      _tempInput = '';
    });
    _speak(_getPrompt()).then((_) {
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
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Voice-guided Registration for Visually Impaired Users',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
