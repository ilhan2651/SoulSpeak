import 'package:flutter/material.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/home_page_hard_hearing_impaired.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/profile_page.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/speech_to_text_page.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/tts_text_page.dart';

import 'hard_hearing_impaired/saved_records_page.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;

  const BaseScaffold({
    Key? key,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomSpace = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF36EEE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36EEE0),
        toolbarHeight: 100,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          "assets/images/33.png",
          height: 180,
          width: 180,
        ),
      ),
      body: body,
      bottomNavigationBar: Container(
        height: 120 + bottomSpace,
        color: const Color(0xFF36EEE0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // FAB'lar (2 tane)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFAB(
                  context,
                  icon: Icons.text_fields,
                  color: Colors.blueAccent,
                  tag: "tts",
                  page: TextToSpeechPage(),
                ),
                const SizedBox(width: 16),
                _buildFAB(
                  context,
                  icon: Icons.audiotrack,
                  color: Colors.green,
                  tag: "stt",
                  page: SpeechToTextPage(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Alt bar ikonları (3 tane, SettingsPage çıkarıldı)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomIcon(context, Icons.home, HomePageHardHearing()),
                _buildBottomIcon(context, Icons.text_snippet, SavedRecordsPage()),
                _buildBottomIcon(context, Icons.person, ProfilePage()),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String tag,
        required Widget page,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF36EEE0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 44,
        width: 44,
        child: FloatingActionButton(
          heroTag: tag,
          mini: true,
          backgroundColor: color,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomIcon(BuildContext context, IconData icon, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF36EEE0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: Colors.black),
      ),
    );
  }
}
