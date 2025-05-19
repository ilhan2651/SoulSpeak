
class SavedRecord {
  final String name;
  final String? textPath;
  final String? audioPath;
  final DateTime date;

  SavedRecord({
    required this.name,
    this.textPath,
    this.audioPath,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'textPath': textPath,
      'audioPath': audioPath,
      'date': date.toIso8601String(),
    };
  }

  factory SavedRecord.fromJson(Map<String, dynamic> json) {
    return SavedRecord(
      name: json['name'],
      textPath: json['textPath'],
      audioPath: json['audioPath'],
      date: DateTime.parse(json['date']),
    );
  }
}
