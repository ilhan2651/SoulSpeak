// lib/services/save_record_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:soulspeakma/model/saved_records.dart';
import '../screens/base_scaffold.dart';

class SaveRecordService {
  static Future<String> _getFolderPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/saved_records');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path;
  }

  static Future<void> saveRecord({
    required String name,
    String? textPath,
    String? audioPath,
  }) async {
    final folderPath = await _getFolderPath();
    final recordFile = File('$folderPath/${DateTime.now().millisecondsSinceEpoch}.json');

    final record = SavedRecord(
      name: name,
      textPath: textPath,
      audioPath: audioPath,
      date: DateTime.now(),
    );

    await recordFile.writeAsString(jsonEncode(record.toJson()));
  }

  static Future<List<SavedRecord>> loadRecords() async {
    final folderPath = await _getFolderPath();
    final directory = Directory(folderPath);
    final files = directory.listSync().whereType<File>().toList();

    List<SavedRecord> records = [];
    for (var file in files) {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      records.add(SavedRecord.fromJson(data));
    }
    return records;
  }

  static Future<void> deleteRecord(String filename) async {
    final folderPath = await _getFolderPath();
    final file = File('$folderPath/$filename');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
