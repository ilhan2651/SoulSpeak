import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class TTSService {
  final Dio _dio = Dio();

  // 📌 Emülatör kullanıyorsan bu IP sabit: 10.0.2.2 (localhost yerine geçer)
  final String _baseUrl = "http://192.168.1.83:8000";

  /// Metni REST API'ye gönderip, gelen MP3 dosyasını indirip geçici klasöre kaydeder
  Future<String?> convertTextToSpeech(String text) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/generate-audio",
        data: jsonEncode({"text": text}),
        options: Options(
          headers: {"Content-Type": "application/json"},
          responseType: ResponseType.bytes,
        ),
      );

      // 📁 Geçici klasör yolunu al
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3";

      // 💾 MP3 dosyasını yaz
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      print("✅ MP3 saved at: $filePath");
      return file.path;
    } catch (e) {
      print("❌ Hata: TTSService > convertTextToSpeech > $e");
      return null;
    }
  }
}
