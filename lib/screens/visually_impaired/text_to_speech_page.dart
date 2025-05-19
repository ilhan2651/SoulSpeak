import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
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
  String? _lastAudioPath;
  bool _hasConvertedOnce = false;
  bool _isSpeakingOrPlaying = false;
  bool _isReadingNow = false;
  bool _isGivingInstruction = false;
  bool _hasGivenGoBackInstruction = false;  // Başlangıçta sadece 1 kere söylemek için flag

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _initializeAll();
    });
  }

  Future<void> _initializeAll() async {
    await _tts.setLanguage("en-US");
    bool micReady = await _speech.initialize();
    if (!micReady) {
      await _speakSafe("Microphone could not be initialized.");
      return;
    }
    await _speech.stop();

    _isGivingInstruction = true;
    await _speakSafe("Welcome to Text to Speech. Say 'file' to read a file, 'clipboard' to paste text, or say 'go back' to return to the router page .");
    _hasGivenGoBackInstruction = true;
    _isGivingInstruction = false;

    _startLoop();
  }

  Future<void> _startLoop() async {
    while (mounted) {
      if (!_isSpeakingOrPlaying && !_isReadingNow && !_isGivingInstruction) {
        await _listenForCommand();
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<void> _speakSafe(String text) async {
    try {
      _isSpeakingOrPlaying = true;
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 400));
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      print("TTS error: $e");
    } finally {
      _isSpeakingOrPlaying = false;
    }
  }

  Future<void> _listenForCommand() async {
    await Future.delayed(const Duration(seconds: 1));
    final command = await _getVoiceCommand();

    if (command.isEmpty) return;

    print("Algılandı: $command");

    // Eğer kullanıcı 'go back' dediyse
    if (command.contains("go back") || command.contains("back")) {
      await _speakSafe("Returning to router page.");
      if (mounted) Navigator.pop(context);
      return;
    }

    if (_matchesFileCommand(command)) {
      if (_hasConvertedOnce) {
        await _speakSafe("This will override the previous audio file.");
      }
      await _speakSafe("File selected. You will be redirected to your device’s file selection page.");
      await _handleFileInput();
    } else if (_matchesClipboardCommand(command)) {
      if (_hasConvertedOnce) {
        await _speakSafe("This will override the previous audio file.");
      }
      await _speakSafe("Clipboard selected. Reading from clipboard text.");
      await _handleClipboardInput();
    } else if (_matchesReplayCommand(command)) {
      if (!_hasConvertedOnce) {
        await _speakSafe("You need to convert text to speech first by saying 'file' or 'clipboard'.");
      } else {
        await _replayLastAudio();
      }
    } else if (_matchesShareCommand(command)) {
      if (!_hasConvertedOnce) {
        await _speakSafe("You need to convert text to speech first by saying 'file' or 'clipboard'.");
      } else {
        await _shareLastAudio();
      }
    } else {
      if (_hasConvertedOnce) {
        // Komut geçerli değilse yine "go back" komutu da dahil hatırlatılır
        await _speakSafe("Command not recognized. You can say 'share', 'replay', 'go back', or start a new conversion with 'file' or 'clipboard'.");
      } else {
        await _speakSafe("Command not recognized. Please say 'file' or 'clipboard' to start, or say 'go back' to return.");
      }
    }
  }

  Future<String> _getVoiceCommand() async {
    if (_isSpeakingOrPlaying || _isReadingNow || _isGivingInstruction) return '';

    String resultText = '';
    int attempt = 0;

    while (resultText.isEmpty && mounted) {
      if (_isSpeakingOrPlaying || _isReadingNow || _isGivingInstruction) return '';

      attempt++;
      print("🎧 Mikrofon dinliyor (deneme $attempt)");

      await _speech.listen(
        onResult: (result) {
          resultText = result.recognizedWords.toLowerCase().trim();
        },
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'en_US',
      );

      await Future.delayed(const Duration(seconds: 5));
      await _speech.stop();

      if (resultText.isEmpty) {
        final prompt = attempt % 3 == 0
            ? "Please say file, clipboard or go back."
            : "Listening again.";
        _isGivingInstruction = true;
        await _speakSafe(prompt);
        _isGivingInstruction = false;
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
      return;
    }
    await _convertAndPlay(text);
  }

  Future<void> _convertAndPlay(String text) async {
    setState(() {
      _isProcessing = true;
      _status = 'Generating voice...';
    });

    final path = await _ttsService.convertTextToSpeech(text);

    if (path != null && File(path).existsSync()) {
      _lastAudioPath = path;
      _hasConvertedOnce = true;
      _isReadingNow = true;

      try {
        await _audioPlayer.setFilePath(path);
        await _audioPlayer.play();
        await _audioPlayer.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed,
        );
        await _speakSafe("Reading completed. To share the audio say 'share', to replay say 'replay', or to convert new text say 'file' or 'clipboard'.");
      } finally {
        _isReadingNow = false;
      }
    } else {
      await _speakSafe("Failed to generate voice.");
    }

    setState(() {
      _isProcessing = false;
      _status = '';
    });
  }

  Future<void> _replayLastAudio() async {
    if (_lastAudioPath != null && File(_lastAudioPath!).existsSync()) {
      _isReadingNow = true;
      try {
        await _audioPlayer.setFilePath(_lastAudioPath!);
        await _audioPlayer.play();
        await _audioPlayer.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed,
        );
        await _speakSafe("Replay finished. You may speak a new command.");
      } finally {
        _isReadingNow = false;
      }
    } else {
      await _speakSafe("No previous audio available to replay.");
    }
  }

  Future<void> _shareLastAudio() async {
    if (_lastAudioPath != null && File(_lastAudioPath!).existsSync()) {
      await Share.shareXFiles([XFile(_lastAudioPath!)], text: 'Here is the voice file.');
    } else {
      await _speakSafe("No voice file available to share.");
    }
  }

  bool _matchesFileCommand(String command) {
    return command.contains("file") || command.contains("fail") || command.contains("fayıl") || command.contains("faıl") || command.contains("five");
  }

  bool _matchesClipboardCommand(String command) {
    return command.contains("clipboard") || command.contains("clip board") || command.contains("klipboard");
  }

  bool _matchesReplayCommand(String command) {
    return command.contains("replay") || command.contains("again") || command.contains("repeat");
  }

  bool _matchesShareCommand(String command) {
    return command.contains("share") || command.contains("send") || command.contains("paylaş");
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
