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
  bool _isSpeaking = false;
  String? _recordedFilePath;
  String _debugText = '';
  String? _recognizedText;

  bool _hasGivenGoBackInstruction = false;

  // 3 tap için değişkenler
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _onTap() {
    _tapCount++;
    _tapTimer?.cancel();

    _tapTimer = Timer(const Duration(seconds: 2), () {
      _tapCount = 0; // 2 saniye içinde yeni tap olmazsa sıfırla
    });

    if (_tapCount >= 3) {
      if (mounted) {
        _speakSafe("Returning to main menu.").then((_) {
          Navigator.pop(context);
        });
      }
      _tapCount = 0;
    }
  }

  Future<void> _initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);

    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      await _speakSafe("Microphone permission is required.");
      return;
    }

    await _repeatInstructions();
  }

  Future<void> _speakSafe(String text) async {
    try {
      _isSpeaking = true;
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      print("TTS error: $e");
    }
  }

  Future<void> _repeatInstructions() async {
    await _speakSafe("Long press to start recording.");
    await _speakSafe("Long press again to stop and choose an action.");
    await _speakSafe("Tap anywhere 3 times quickly to go router page.");
  }

  Future<void> _startRecording() async {
    await _speakSafe("Recording started. You can speak now.");

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
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    _isProcessing = true;
    await Future.delayed(const Duration(milliseconds: 300));
    await _speakSafe("Recording stopped.");
    await Future.delayed(const Duration(milliseconds: 300));
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
      final isMeaningful = text.toLowerCase() != 'could not understand.';

      setState(() {
        _recognizedText = text;
        _debugText = '📝 Text: $text';
      });

      await _speakSafe("Analysis complete.");

      if (!isMeaningful) {
        await _speakSafe("Sorry, I couldn't understand the recording.");
        _isProcessing = false;
        await _repeatInstructions();
        return;
      }

      final txtFile = await _saveTextFile(text);

      await _speakSafe("What do you want to do with the result?");

      String? action;
      do {
        await _speakSafe("Say share, save or copy.");
        final resultText = await _listenForCommand();
        print('[STT] Full recognized command: \$resultText');
        if (resultText == null) continue;

        final lowerText = resultText.toLowerCase();
        if (lowerText.contains("go back") || lowerText.contains("back")) {
          await _speakSafe("Returning to main menu.");
          if (mounted) Navigator.pop(context);
          return;
        } else if (lowerText.contains("share") || lowerText.contains("shave") || lowerText.contains("send") || lowerText.contains("forward")) {
          action = "share";
        } else if (lowerText.contains("copy") || lowerText.contains("coffee") || lowerText.contains("clipboard") || lowerText.contains("duplicate")) {
          action = "copy";
        } else if (lowerText.contains("save") || lowerText.contains("safe") || lowerText.contains("store") || lowerText.contains("download")) {
          action = "save";
        } else {
          action = null;
        }

        if (action == "share") {
          await Share.shareXFiles([XFile(txtFile.path)], text: "Here is the recognized text.");
          await _speakSafe("Text shared.");
        } else if (action == "copy") {
          await FlutterClipboard.copy(text);
          await _speakSafe("Text copied to clipboard.");
        } else if (action == "save") {
          final dir = await getExternalStorageDirectory();
          final folderPath = '${dir!.path}/SoulSpeak';
          await Directory(folderPath).create(recursive: true);

          final savedFile = File('$folderPath/recognized_${DateTime.now().millisecondsSinceEpoch}.txt');
          await savedFile.writeAsString(text);

          await _speakSafe("Text saved to SoulSpeak folder.");
          print('[SAVE] File saved to: \${savedFile.path}');
        } else {
          await _speakSafe("No valid command detected. Please try again.");
        }
      } while (action != "share" && action != "copy" && action != "save");

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
    print('[STT] Waiting for TTS to finish before listening...');
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Future.delayed(const Duration(milliseconds: 500));

    print('[STT] Initializing speech recognition...');
    bool available = await _speech.initialize();
    if (!available) {
      print('[STT] Initialization failed');
      return null;
    }

    String command = '';

    while (command.isEmpty) {
      print('[STT] Listening for command...');
      await _speech.listen(
        onResult: (result) {
          command = result.recognizedWords.toLowerCase().trim();
          print('[STT] Heard: \$command');
        },
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 4),
        partialResults: false,
        localeId: 'en_US',
      );

      await Future.delayed(const Duration(seconds: 6));
      await _speech.stop();

      if (command.isEmpty) {
        await _speakSafe("I didn’t hear anything. Listening again.");
      }
    }

    return command;
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

          if (_isRecording && !_isSpeaking && !_speech.isListening) {
            await _stopRecording();
          } else if (!_isRecording && !_isSpeaking && !_speech.isListening) {
            await _startRecording();
          } else {
            print("[DEBUG] Ignored long press: speaking or listening in progress.");
          }
        },
        onTap: _onTap, // 3 kere tap ile geri dönmeyi buraya bağladık
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
              const SizedBox(height: 20),
              const Text(
                'Tap anywhere 3 times quickly to go back to choose page.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    _tapTimer?.cancel();
    super.dispose();
  }
}
