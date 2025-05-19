import 'package:flutter/material.dart';
import 'package:soulspeakma/model/saved_records.dart';
import 'package:soulspeakma/screens/hard_hearing_impaired/saved_record_detail_page.dart';
import 'package:soulspeakma/services/save_records_service.dart';
import '../base_scaffold.dart';

class SavedRecordsPage extends StatefulWidget {
  const SavedRecordsPage({Key? key}) : super(key: key);

  @override
  State<SavedRecordsPage> createState() => _SavedRecordsPageState();
}

class _SavedRecordsPageState extends State<SavedRecordsPage> {
  List<SavedRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await SaveRecordService.loadRecords();
    setState(() {
      _records = records;
    });
  }

  Future<void> _deleteRecord(SavedRecord record) async {
    final filename = record.date.millisecondsSinceEpoch.toString() + '.json';
    await SaveRecordService.deleteRecord(filename);
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _records.isEmpty
            ? const Center(child: Text("No saved records found."))
            : ListView.builder(
          itemCount: _records.length,
          itemBuilder: (context, index) {
            final record = _records[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(record.name),
                subtitle: Text(
                  "Date: ${record.date.toLocal().toString().split(' ')[0]}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRecord(record),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedRecordDetailPage(record: record),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
