import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'token_storage_service.dart';

class AuthService {
  // Tự động chọn baseUrl dựa trên platform
  String get baseUrl {
    if (kIsWeb) {
      // Chrome/Web: dùng localhost
      return "http://localhost:3000/api/auth";
    } else if (!kIsWeb && Platform.isAndroid) {
      // Android Emulator: dùng 10.0.2.2 (trỏ đến localhost của máy host)
      return "http://10.0.2.2:3000/api/auth";
    } else {
      // Windows/iOS/macOS Desktop: dùng localhost
      return "http://localhost:3000/api/auth";
    }
  }
  
  final TokenStorageService _tokenStorage = TokenStorageService();

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
      final token = jsonDecode(response.body)['token'];
      // Tự động lưu token vào secure storage
      await _tokenStorage.saveToken(token);
      return token;
    }
    return null;
  }

  // UC-03: Lấy thông tin hồ sơ
  Future<Map<String, dynamic>?> getUserProfile([String? token]) async {
    try {
      // Nếu không truyền token, lấy từ storage
      token ??= await _tokenStorage.getToken();
      if (token == null) return null;

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

  Future<bool> updateProfile(String newName, [String? token]) async {
    // Nếu không truyền token, lấy từ storage
    token ??= await _tokenStorage.getToken();
    if (token == null) return false;

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

  Future<bool> updateFinancialInfo(
    int? monthlyIncome,
    int? payDay, [
    String? token,
  ]) async {
    token ??= await _tokenStorage.getToken();
    if (token == null) return false;

    final Map<String, dynamic> body = {};
    if (monthlyIncome != null) body['monthly_income'] = monthlyIncome;
    if (payDay != null) body['pay_day'] = payDay;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      body: jsonEncode(body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // Cập nhật currency (khi chọn ngôn ngữ)
  Future<bool> updateCurrency(String currency, [String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/users/me/currency'),
        body: jsonEncode({'currency': currency}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasToken();
  }
}
//