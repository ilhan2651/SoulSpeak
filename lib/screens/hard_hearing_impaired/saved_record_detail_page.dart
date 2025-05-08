import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../model/saved_records.dart';

class SavedRecordDetailPage extends StatefulWidget {
  final SavedRecord record;

  const SavedRecordDetailPage({Key? key, required this.record}) : super(key: key);

  @override
  State<SavedRecordDetailPage> createState() => _SavedRecordDetailPageState();
}

class _SavedRecordDetailPageState extends State<SavedRecordDetailPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (widget.record.audioPath != null) {
      _audioPlayer.setFilePath(widget.record.audioPath!);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.record.textPath != null && widget.record.textPath!.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    widget.record.textPath!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (widget.record.audioPath != null)
              ElevatedButton.icon(
                onPressed: _toggleAudio,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? "Pause Audio" : "Play Audio"),
              ),
          ],
        ),
      ),
    );
  }
}
