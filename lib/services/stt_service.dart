import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';

class STTService {
  final Dio _dio = Dio();
  final String _baseUrl = "http://192.168.0.3:8000";

  /// Hem File hem XFile destekler
  Future<Map<String, dynamic>?> analyzeAudio(dynamic file) async {
    try {
      // path ve dosya adı belirle
      final String path = file.path;
      final String name = file is XFile
          ? file.name
          : path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(path, filename: name),
      });

      final response = await _dio.post(
        "$_baseUrl/stt/analyze",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        print("STT failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("STTService error: $e");
      return null;
    }
  }
}
