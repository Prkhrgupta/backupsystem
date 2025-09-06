import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:archive/archive_io.dart';
import 'package:swift_cloud_backup/utils/notification_system.dart';

class AdminApi {
  static const String baseUrl = "http://localhost:8080/";
  static const String minioBaseUrl = "http://localhost:9000/";

  /// Admin Login
  Future<bool> adminLogin(String username, String password) async {
    final url = Uri.parse('${baseUrl}admin/get-admin-details');
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", username);
        await prefs.setString("password", password);
        await prefs.setString("firmName", data["name"]);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  /// Get Presigned URL from backend
  Future<String?> getPresignedUrl(String objectName) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      print("No saved credentials found.");
      return null;
    }

    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    final url = Uri.parse(
        "${baseUrl}admin/minio/presigned-url/get?objectName=$objectName");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(
            "Failed to get presigned URL: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching presigned URL: $e");
      return null;
    }
  }

  /// Download object from MinIO
  Future<File?> downloadFromMinio(String objectName, String savePath) async {
    final presignedUrl = await getPresignedUrl(objectName);

    if (presignedUrl == null) {
      print("No presigned URL available.");
      return null;
    }

    try {
      final response = await http.get(Uri.parse(presignedUrl));

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        print("File saved at $savePath");
        return file;
      } else {
        print("Failed to download object: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error downloading object: $e");
      return null;
    }
  }

  /// Fetch list of objects
  Future<List<MinioObject>> listObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      print("No saved credentials found.");
      return [];
    }

    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    final url = Uri.parse("${baseUrl}admin/minio/list-objects");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => MinioObject.fromJson(e)).toList();
      } else {
        print(
            "Failed to fetch object list: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching object list: $e");
      return [];
    }
  }

  /// Upload file to MinIO
  Future<bool> uploadToMinio(String objectName, File file) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      print("No saved credentials found.");
      return false;
    }

    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    final url = Uri.parse(
        "${baseUrl}admin/minio/presigned-url/put?objectName=$objectName");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode != 200) {
        print(
            "Failed to get presigned policy: ${response.statusCode} - ${response.body}");
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final bucketUrl = Uri.parse("$minioBaseUrl$username");
      final request = http.MultipartRequest("POST", bucketUrl);

      request.fields["key"] = objectName;
      request.fields["x-amz-algorithm"] = data["x-amz-algorithm"];
      request.fields["x-amz-credential"] = data["x-amz-credential"];
      request.fields["x-amz-date"] = data["x-amz-date"];
      request.fields["policy"] = data["policy"];
      request.fields["x-amz-signature"] = data["x-amz-signature"];

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 204) {
        print("✅ Upload successful!");
        return true;
      } else {
        print("❌ Upload failed: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error uploading to MinIO: $e");
      return false;
    }
  }

  /// Run backup: zip folder and upload
  Future<bool> runBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString("selectedDirectory");
    final username = prefs.getString("username");

    if (path == null || username == null) {
      print("No folder selected or user not logged in.");
      return false;
    }

    final folder = Directory(path);
    if (!await folder.exists()) {
      print("Selected folder does not exist.");
      return false;
    }

    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      final zipFileName = "${username}_$formattedDate.zip";
      final zipFilePath = p.join(Directory.systemTemp.path, zipFileName);

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      encoder.addDirectory(folder, includeDirName: false);
      encoder.close();

      final zipFile = File(zipFilePath);

      print("Backup created at $zipFilePath, uploading...");
      NotificationService().showNotification(
        title: "Backup Successful",
        body: "$zipFileName uploaded successfully ✅",
        type: NotificationType.success,
      );
      final uploaded = await uploadToMinio(zipFileName, zipFile);
      await zipFile.delete();
      return uploaded;
    } catch (e) {
      print("Error running backup: $e");
      return false;
    }
  }
}

/// Model class for Minio object
class MinioObject {
  final String lastModifiedDate;
  final String fileName;
  final int size;

  MinioObject({
    required this.lastModifiedDate,
    required this.fileName,
    required this.size,
  });

  factory MinioObject.fromJson(Map<String, dynamic> json) {
    return MinioObject(
      lastModifiedDate: json['lastModifiedDate'],
      fileName: json['fileName'],
      size: json['size'],
    );
  }
}
