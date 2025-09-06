import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/login_auth_api.dart';

class RestorePage extends StatefulWidget {
  const RestorePage({super.key});

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  late Future<List<MinioObject>> _futureFiles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFiles();
  }

  void _loadFiles() {
    _futureFiles = AdminApi().listObjects();
  }

  Future<void> _refreshFiles() async {
    setState(() {
      _loadFiles();
    });
  }

  // Convert UTC to IST and format in 12-hour with AM/PM
  String formatDateTime(String isoDate) {
    try {
      final dateTimeUtc = DateTime.parse(isoDate);
      final dateTimeIst = dateTimeUtc.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTimeIst);
    } catch (e) {
      return isoDate; // fallback if parsing fails
    }
  }

  Future<void> _restoreFile(MinioObject file) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) return;

      final savePath = "$selectedDirectory/${file.fileName}";
      final downloadedFile =
      await AdminApi().downloadFromMinio(file.fileName, savePath);

      if (downloadedFile != null && downloadedFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Downloaded ${file.fileName} to $savePath")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to download ${file.fileName}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploaded Files"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFiles,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<MinioObject>>(
          future: _futureFiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No files found."));
            }

            final files = snapshot.data!;

            return DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
              columns: const [
                DataColumn2(label: Text("File Name"), size: ColumnSize.L),
                DataColumn2(label: Text("Uploaded Date"), size: ColumnSize.M),
                DataColumn2(label: Text("Size (KB)"), numeric: true, size: ColumnSize.S),
                DataColumn2(label: Text("Action"), size: ColumnSize.S),
              ],
              rows: files.map((file) {
                return DataRow(cells: [
                  DataCell(Text(file.fileName)),
                  DataCell(Text(formatDateTime(file.lastModifiedDate))),
                  DataCell(Text("${(file.size / 1024).toStringAsFixed(2)}")),
                  DataCell(
                    ElevatedButton(
                      onPressed: () => _restoreFile(file),
                      child: const Text("Restore"),
                    ),
                  ),
                ]);
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
