import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AdminApi {

  Future<bool> getAdminDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString("username");
    final String? password = prefs.getString("password");
    if(username == null || password == null) {
      return false;
    }
    final url = Uri.parse('http://localhost:8080/admin/get-admin-details');
    String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    try {
      final response = await http.get(
        url, 
        headers: {
          'Authorization': basicAuth
        }
      );

      if(response.statusCode == 200) {
        return true;
      } else {
        return false;
      }

    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
