import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:lottie/lottie.dart';
import 'package:soulspeakma/services/save_records_service.dart';
import 'package:soulspeakma/services/stt_service.dart';
import '../base_scaffold.dart';
import 'dart:io';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  final STTService _sttService = STTService();
  bool _isProcessing = false;
  bool _isConverted = false;
  String _convertedText = "";
  String _detectedEmotion = "";
  String? _selectedAudioPath;

  Future<void> _pickAudioFile() async {
    final typeGroup = XTypeGroup(
      label: 'audio',
      extensions: ['mp3', 'wav', 'm4a'],
    );

    try {
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        return;
      }

      final extension = file.name.split('.').last.toLowerCase();
      if (!['mp3', 'wav', 'm4a'].contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unsupported file type!")),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
        _isConverted = false;
      });

      final result = await _sttService.analyzeAudio(file);

      if (result != null) {
        setState(() {
          _convertedText = result["text"] ?? "No transcription found.";
          _detectedEmotion = result["emotion"] ?? "Unknown";
          _selectedAudioPath = file.path;
          _isConverted = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to transcribe audio.")),
        );
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _clearText() {
    setState(() {
      _isConverted = false;
      _convertedText = "";
      _detectedEmotion = "";
      _selectedAudioPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAudioFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select Audio File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isProcessing)
                  Center(
                    child: Column(
                      children: [
                        const Text("Converting speech to text..."),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 400,
                          width: 500,
                          child: Lottie.asset(
                            'assets/animations/stt.json',
                            repeat: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isConverted && !_isProcessing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: TextEditingController(text: _convertedText),
                        maxLines: null,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Transcribed Text",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Detected Emotion: $_detectedEmotion",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _clearText,
                              child: const Text("Clear"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveRecord,
                              icon: const Icon(Icons.save),
                              label: const Text("Save to Pano"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_convertedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No transcription to save.")),
      );
      return;
    }

    final name = await _getRecordName();
    if (name == null || name.isEmpty) return;

    await SaveRecordService.saveRecord(
      name: name,
      textPath: _convertedText,
      audioPath: _selectedAudioPath,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Record saved!")),
    );
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