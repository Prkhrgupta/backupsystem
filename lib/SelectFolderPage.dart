import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectFolderPage extends StatefulWidget {
  const SelectFolderPage({super.key});

  @override
  State<SelectFolderPage> createState() => _SelectFolderPageState();
}

class _SelectFolderPageState extends State<SelectFolderPage> {
  final TextEditingController _controller = TextEditingController();
  static const String _prefKey = "selectedDirectory";

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
  }

  /// Load folder path from shared_preferences
  Future<void> _loadSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_prefKey);

    if (savedPath != null && mounted) {
      setState(() {
        _controller.text = savedPath;
      });
    }
  }

  /// Pick folder and save it
  Future<void> _pickFolder() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      setState(() {
        _controller.text = directoryPath;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, directoryPath); // persist folder
    }
  }

  /// Show a simple alert when Backup Now is pressed
  void _backupNow() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Backup"),
        content: Text(
          _controller.text.isEmpty
              ? "No folder selected!"
              : "Backup started to:\n${_controller.text}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Expanded TextField to display path
              Expanded(
                child: TextField(
                  controller: _controller,
                  readOnly: true, // prevent manual typing
                  decoration: const InputDecoration(
                    labelText: "Selected Folder",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Choose Directory button
              ElevatedButton(
                onPressed: _pickFolder,
                child: const Text("Choose"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Backup Now button
          ElevatedButton.icon(
            onPressed: _backupNow,
            icon: const Icon(Icons.backup),
            label: const Text("Backup Now"),
          ),
        ],
      ),
    );
  }
}
