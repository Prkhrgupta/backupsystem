import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MinioClient {

  Future<void> createPost() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": "Flutter HTTP",
        "body": "Explaining CRUD with examples",
        "userId": 1
      }),
    );

    if (response.statusCode == 201) {
      print("✅ Post Created: ${response.body}");
    } else {
      print("❌ Failed to create post: ${response.statusCode}");
    }
  }
}
