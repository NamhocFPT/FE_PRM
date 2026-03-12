import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'token_storage_service.dart';

class JarProfileService {
  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api/jar-profiles";
    } else if (!kIsWeb && Platform.isAndroid) {
      return "http://10.0.2.2:3000/api/jar-profiles";
    } else {
      return "http://localhost:3000/api/jar-profiles";
    }
  }

  final TokenStorageService _tokenStorage = TokenStorageService();

  // Check if user has active jar profile
  Future<bool> hasActiveProfile([String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/active'),
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

  // Get active jar profile
  Future<Map<String, dynamic>?> getActiveProfile([String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        if (payload is Map && payload['data'] is Map) {
          return Map<String, dynamic>.from(payload['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all jar profiles
  Future<List<Map<String, dynamic>>?> getAllProfiles([String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final data = payload is Map ? payload['data'] : null;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create default jar profile
  // UC-04: Create Jar Profile
  Future<Map<String, dynamic>?> createProfile(
    String profileName, [
    String? token,
  ]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          'profile_name': profileName,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final payload = jsonDecode(response.body);
        if (payload is Map && payload['data'] is Map) {
          return Map<String, dynamic>.from(payload['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // UC-05: Update jar percentages
  Future<bool> updateJarPercentages(
    String profileId,
    List<Map<String, dynamic>> jars, [
    String? token,
  ]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/$profileId'),
        body: jsonEncode({'jars': jars}),
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

  // UC-06: Activate jar profile
  Future<bool> activateProfile(String profileId, [String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/$profileId/activate'),
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
  // Lấy danh sách jar cho dropdown (UC-09)
  // GET /api/jar-profiles/jars
  Future<List<Map<String, dynamic>>?> getJarList([String? token]) async {
    try {
      token ??= await _tokenStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/jars'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final data = payload is Map ? payload['data'] : null;
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item)),
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
