import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soulspeakma/screens/visually_impaired/stt_command_page.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/speech_to_text_page.dart';
import 'package:soulspeakma/screens/splash_screen.dart';
import 'package:soulspeakma/screens/visually_impaired/text_to_speech_page.dart';

import 'screens/visually_impaired/registratrion_page_visually_impaired.dart';
import 'screens/visually_impaired/router_voice_command_page.dart';


void main() {
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulSpeak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RouterVoiceCommandPage(),
    );
  }
}
