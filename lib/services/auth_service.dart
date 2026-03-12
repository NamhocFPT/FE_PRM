import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

class AuthService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api/auth";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator
        return "http://10.0.2.2:3000/api/auth";

      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return "http://localhost:3000/api/auth";
    }
  }

  Future<int> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': name,
        'email': email,
        'password': password,
      }),
    );

    return response.statusCode;
  }

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      await _tokenStorage.saveToken(token);
      return token;
    }

    return null;
  }

  Future<Map<String, dynamic>?> getUserProfile([String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(
    String? newName, {
    String? token,
    int? monthlyIncome,
    int? payDay,
    Map<String, dynamic>? jars,
  }) async {
    token ??= await _tokenStorage.getToken();
    if (token == null) return false;

    final Map<String, dynamic> body = {};
    if (newName != null) body['full_name'] = newName;
    if (monthlyIncome != null) body['monthly_income'] = monthlyIncome;
    if (payDay != null) body['pay_day'] = payDay;
    if (jars != null) body['jars'] = jars;

    if (body.isEmpty) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
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

    if (body.isEmpty) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  Future<bool> updateCurrency(String currency, [String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/users/me/currency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'currency': currency}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasToken();
  }
}