import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://10.0.2.2:3000/api/auth";

  Future<int> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: jsonEncode({
        'full_name': name,
        'email': email,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode;
  }

  // UC-02: Đăng nhập (Login)
  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
    return null;
  }

  // UC-03: Lấy thông tin hồ sơ
  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/me',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(
          response.body,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile(String token, String newName) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      body: jsonEncode({
        'full_name': newName,
      }), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}
//