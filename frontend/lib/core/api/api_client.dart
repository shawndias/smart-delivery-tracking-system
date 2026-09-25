import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    
    // For Android Emulators, uncomment this:
    // if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    
    // For Physical Phone via Wi-Fi (current setup):
    if (Platform.isAndroid || Platform.isIOS) return 'http://192.168.0.110:8000/api';
    
    return 'http://127.0.0.1:8000/api';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
