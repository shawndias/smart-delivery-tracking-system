import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<User?> login(String email, String password) async {
    final response = await _apiClient.post('/login', body: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      final token = data['access_token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(data['user']));
      
      return user;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Login failed');
    }
  }

  Future<User?> register(String name, String email, String password, String role) async {
    final response = await _apiClient.post('/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      final token = data['access_token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(data['user']));
      
      return user;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }
}
