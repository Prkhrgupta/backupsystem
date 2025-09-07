import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  void initState() {
    super.initState();
    _refreshFiles(); // auto-refresh on first load
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
      return DateFormat('dd MMM yyyy • hh:mm a').format(dateTimeIst);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploaded Files"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _refreshFiles,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        "Refresh to see any new uploads",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final sizeInMB =
                      (file.size / (1024 * 1024)).toStringAsFixed(2);

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // File name
                              Row(
                                children: [
                                  const Icon(Icons.insert_drive_file,
                                      color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.fileName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Highlighted Date
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatDateTime(file.lastModifiedDate),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // File size
                              Row(
                                children: [
                                  const Icon(Icons.storage, size: 16),
                                  const SizedBox(width: 6),
                                  Text("Size: $sizeInMB MB"),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Action
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () => _restoreFile(file),
                                  icon: const Icon(Icons.download),
                                  label: const Text("Restore"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
