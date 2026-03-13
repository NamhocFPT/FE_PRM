import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'token_storage_service.dart';

class DashboardService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  String _getBaseUrl(String path) {
    if (kIsWeb) {
      return "http://localhost:3000/api$path";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api$path";
    } else {
      return "http://localhost:3000/api$path";
    }
  }

  // Lấy dữ liệu thống kê tháng
  // GET /api/dashboard/monthly?month=YYYY-MM
  Future<Map<String, dynamic>> getMonthlyDashboard(String month) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    final uri = Uri.parse(_getBaseUrl('/dashboard/monthly')).replace(
      queryParameters: {'month': month},
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      // Backend trả về object trực tiếp (không wrap trong {success, data})
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      return {};
    } else {
      final payload = jsonDecode(response.body);
      throw Exception(payload['message'] ?? 'Lỗi khi tải dữ liệu thống kê');
    }
  }

  // Lấy báo cáo lịch sử (các tháng trước)
  // GET /api/reports/history?months=6
  Future<List<dynamic>> getReportsHistory({int months = 6}) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    final uri = Uri.parse(_getBaseUrl('/reports/history')).replace(
      queryParameters: {'months': months.toString()},
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      // Backend trả về array trực tiếp (không wrap trong {success, data})
      if (payload is List<dynamic>) {
        return payload;
      }
      return [];
    } else {
      final payload = jsonDecode(response.body);
      throw Exception(payload['message'] ?? 'Lỗi khi tải báo cáo lịch sử');
    }
  }
}
