import 'package:flutter/material.dart';

class RestorePage extends StatelessWidget {
  const RestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy file list
    final List<Map<String, String>> files = [
      {"fileName": "backup1.zip", "uploadedDate": "2025-08-01"},
      {"fileName": "backup2.zip", "uploadedDate": "2025-08-10"},
      {"fileName": "backup3.zip", "uploadedDate": "2025-08-20"},
    ];

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Uploaded Files")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // You already used Expanded which is good
            Expanded(
              child: SingleChildScrollView(
                // vertical scrolling for rows
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  // horizontal scrolling when columns overflow
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // ensure the DataTable takes at least the full screen width
                    constraints: BoxConstraints(minWidth: screenWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      // use MaterialStateProperty for headingRowColor
                      headingRowColor:
                      WidgetStateProperty.all(Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text("File Name")),
                        DataColumn(label: Text("Uploaded Date")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: files.map((file) {
                        return DataRow(cells: [
                          DataCell(Text(file["fileName"] ?? "")),
                          DataCell(Text(file["uploadedDate"] ?? "")),
                          DataCell(
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Restored ${file["fileName"]}")),
                                );
                              },
                              child: const Text("Restore"),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
