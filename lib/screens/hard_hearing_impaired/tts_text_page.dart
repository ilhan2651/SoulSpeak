import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soulspeakma/services/save_records_service.dart';
import 'package:soulspeakma/services/tts_service.dart';
import '../base_scaffold.dart';

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({Key? key}) : super(key: key);

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Convert Text to Speech",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Enter text here...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _textController.clear();
                  setState(() => _audioUrl = null);
                },
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text("Clear", style: TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 10),

            if (_audioUrl != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Audio Preview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final total = _audioPlayer.duration ?? Duration.zero;
                          return Column(
                            children: [
                              Slider(
                                value: position.inSeconds.toDouble(),
                                max: total.inSeconds.toDouble(),
                                onChanged: (value) {
                                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                              Text("${_formatTime(position)} / ${_formatTime(total)}"),
                            ],
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _audioPlayer.play(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause),
                            onPressed: () => _audioPlayer.pause(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: _downloadAudio,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _convertToSpeech,
              icon: const Icon(Icons.audiotrack),
              label: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Convert and Play"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            if (_audioUrl != null)
              ElevatedButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.save),
                label: const Text("Save to Pano"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToSpeech() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter text")));
      return;
    }

    setState(() {
      _isLoading = true;
      _audioUrl = null;
    });

    final ttsService = TTSService();
    final filePath = await ttsService.convertTextToSpeech(text);

    if (filePath != null) {
      await _audioPlayer.setFilePath(filePath);
      setState(() {
        _audioUrl = filePath;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to generate speech.")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _downloadAudio() async {
    if (_audioUrl == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = "tts_${DateTime.now().millisecondsSinceEpoch}.mp3";
      final savePath = "${dir.path}/$fileName";

      await File(_audioUrl!).copy(savePath);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to: $savePath")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _saveRecord() async {
    if (_audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No audio to save.")));
      return;
    }

    final name = await _getRecordName();
    if (name == null || name.isEmpty) return;

    await SaveRecordService.saveRecord(
      name: name,
      audioPath: _audioUrl!,
      textPath: _textController.text.trim(), // 📌 BURASI DÜZELTİLDİ
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record saved!")));
  }

  Future<String?> _getRecordName() async {
    String input = "";
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter a name for the record"),
        content: TextField(
          autofocus: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(hintText: "Record name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, input),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
