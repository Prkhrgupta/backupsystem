import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:archive/archive_io.dart';
import 'package:swift_cloud_backup/utils/notification_system.dart';

class AdminApi {
  static const String baseUrl = String.fromEnvironment("BASE_URL", defaultValue: "https://sitswiftcloud.in/");
  static const String minioBaseUrl = String.fromEnvironment("MINIO_BASE_URL", defaultValue: "https://s3.sitswiftcloud.in/");  /// Admin Login


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

        NotificationService().showNotification(
          title: "Login Successful",
          body: "Welcome back, ${data["name"]} ✅",
          type: NotificationType.success,
        );

        return true;
      } else {
        NotificationService().showNotification(
          title: "Login Failed",
          body: "Invalid credentials ❌",
          type: NotificationType.error,
        );
        return false;
      }
    } catch (e) {
      NotificationService().showNotification(
        title: "Login Error",
        body: "Error: $e",
        type: NotificationType.error,
      );
      return false;
    }
  }

  /// Get Presigned URL from backend
  Future<String?> getPresignedUrl(String objectName) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      NotificationService().showNotification(
        title: "Presigned URL Error",
        body: "No saved credentials found ⚠️",
        type: NotificationType.error,
      );
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
        NotificationService().showNotification(
          title: "Presigned URL Failed",
          body: "Error: ${response.statusCode} - ${response.body}",
          type: NotificationType.error,
        );
        return null;
      }
    } catch (e) {
      NotificationService().showNotification(
        title: "Presigned URL Exception",
        body: "Error: $e",
        type: NotificationType.error,
      );
      return null;
    }
  }

  /// Download object from MinIO
  Future<File?> downloadFromMinio(String objectName, String savePath) async {
    final presignedUrl = await getPresignedUrl(objectName);

    if (presignedUrl == null) {
      return null;
    }

    try {
      final response = await http.get(Uri.parse(presignedUrl));

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        NotificationService().showNotification(
          title: "Download Successful",
          body: "$objectName saved at $savePath ✅",
          type: NotificationType.success,
        );

        return file;
      } else {
        NotificationService().showNotification(
          title: "Download Failed",
          body: "Error: ${response.statusCode}",
          type: NotificationType.error,
        );
        return null;
      }
    } catch (e) {
      NotificationService().showNotification(
        title: "Download Error",
        body: "Error: $e",
        type: NotificationType.error,
      );
      return null;
    }
  }

  /// Fetch list of objects
  Future<List<MinioObject>> listObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      NotificationService().showNotification(
        title: "List Error",
        body: "No saved credentials found ⚠️",
        type: NotificationType.error,
      );
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
        NotificationService().showNotification(
          title: "Fetch Failed",
          body: "Error: ${response.statusCode} - ${response.body}",
          type: NotificationType.error,
        );
        return [];
      }
    } catch (e) {
      NotificationService().showNotification(
        title: "Fetch Error",
        body: "Error: $e",
        type: NotificationType.error,
      );
      return [];
    }
  }

  /// Upload file to MinIO
  Future<bool> uploadToMinio(String objectName, File file) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      NotificationService().showNotification(
        title: "Upload Error",
        body: "No saved credentials found ⚠️",
        type: NotificationType.error,
      );
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
        NotificationService().showNotification(
          title: "Upload Failed",
          body: "Presigned policy error: ${response.statusCode}",
          type: NotificationType.error,
        );
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
        NotificationService().showNotification(
          title: "Upload Successful",
          body: "$objectName uploaded successfully ✅",
          type: NotificationType.success,
        );
        return true;
      } else {
        NotificationService().showNotification(
          title: "Upload Failed",
          body: "Error: ${res.statusCode} - ${res.body}",
          type: NotificationType.error,
        );
        return false;
      }
    } catch (e) {
      NotificationService().showNotification(
        title: "Upload Error",
        body: "Error: $e",
        type: NotificationType.error,
      );
      return false;
    }
  }

  /// Run backup: zip folder and upload
  Future<bool> runBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString("selectedDirectory");
    final username = prefs.getString("username");

    if (path == null || username == null) {
      NotificationService().showNotification(
        title: "Backup Error",
        body: "No folder selected or user not logged in ⚠️",
        type: NotificationType.error,
      );
      return false;
    }

    final folder = Directory(path);
    if (!await folder.exists()) {
      NotificationService().showNotification(
        title: "Backup Error",
        body: "Selected folder does not exist ⚠️",
        type: NotificationType.error,
      );
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

      NotificationService().showNotification(
        title: "Backup Created",
        body: "Uploading $zipFileName ⏳",
        type: NotificationType.info,
      );

      final uploaded = await uploadToMinio(zipFileName, zipFile);
      await zipFile.delete();
      return uploaded;
    } catch (e) {
      NotificationService().showNotification(
        title: "Backup Error",
        body: "Error: $e",
        type: NotificationType.error,
      );
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
