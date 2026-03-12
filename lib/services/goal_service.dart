import 'dart:convert';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

class GoalService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api/goals";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2:3000/api/goals";
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return "http://localhost:3000/api/goals";
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/goals – lấy danh sách mục tiêu
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        // Nếu API trả về { goals: [...] } hoặc { data: [...] }
        if (decoded is Map) {
          final list = decoded['goals'] ?? decoded['data'] ?? decoded['result'];
          if (list is List) {
            return List<Map<String, dynamic>>.from(list);
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('GoalService.getGoals error: $e');
      return [];
    }
  }

  /// POST /api/goals – tạo mục tiêu mới
  Future<Map<String, dynamic>?> createGoal({
    required String name,
    required double targetAmount,
    String jarKey = 'saving',
    String? deadline,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'target_amount': targetAmount,
        'jar_key': jarKey,
      };
      if (deadline != null && deadline.isNotEmpty) {
        body['deadline'] = deadline;
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('GoalService.createGoal error: $e');
      return null;
    }
  }

  /// PATCH /api/goals/:id – cập nhật trạng thái / current_amount
  Future<bool> updateGoal(String goalId, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$goalId'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('GoalService.updateGoal error: $e');
      return false;
    }
  }

  /// POST /api/goals/:id/add-progress – cộng thêm tiền
  Future<bool> addProgress(String goalId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$goalId/add-progress'),
        headers: await _headers(),
        body: jsonEncode({'amount': amount}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('GoalService.addProgress error: $e');
      return false;
    }
  }
}
