import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'token_storage_service.dart';

class TransactionService {
  String get baseUrl {
    if (kIsWeb) {
      return "https://miwcerg73wscwzrkrqchvautme0pnoxj.lambda-url.us-east-1.on.aws/api/transactions";
    } else if (!kIsWeb && Platform.isAndroid) {
      return "https://miwcerg73wscwzrkrqchvautme0pnoxj.lambda-url.us-east-1.on.aws/api/transactions";
    } else {
      return "https://miwcerg73wscwzrkrqchvautme0pnoxj.lambda-url.us-east-1.on.aws/api/transactions";
    }
  }

  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Helper: lấy headers với token
  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════
  // UC-09: Thêm chi tiêu
  // POST /api/transactions
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> createExpense({
    required double amount,
    required String jarKey,
    required DateTime occurredAt,
    String? note,
    String currency = 'VND',
  }) async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'jar_key': jarKey,
          'note': note ?? '',
          'occurred_at': occurredAt.toIso8601String(),
          'currency': currency,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Thêm chi tiêu thành công',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // UC-10: Sửa chi tiêu
  // PUT /api/transactions/:id
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> updateExpense({
    required String id,
    double? amount,
    String? jarKey,
    String? note,
    DateTime? occurredAt,
    String? currency,
  }) async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    try {
      final Map<String, dynamic> bodyData = {};
      if (amount != null) bodyData['amount'] = amount;
      if (jarKey != null) bodyData['jar_key'] = jarKey;
      if (note != null) bodyData['note'] = note;
      if (occurredAt != null) bodyData['occurred_at'] = occurredAt.toIso8601String();
      if (currency != null) bodyData['currency'] = currency;

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: jsonEncode(bodyData),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Cập nhật thành công',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // UC-10: Xoá chi tiêu
  // DELETE /api/transactions/:id
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> deleteExpense(String id) async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Xoá thành công',
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // UC-11: Chuyển tiền giữa các lọ
  // POST /api/transactions/transfer
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> createTransfer({
    required String fromJarKey,
    required String toJarKey,
    required double amount,
    required DateTime occurredAt,
    String currency = 'VND',
    String? note,
  }) async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transfer'),
        headers: headers,
        body: jsonEncode({
          'from_jar_key': fromJarKey,
          'to_jar_key': toJarKey,
          'amount': amount,
          'occurred_at': occurredAt.toIso8601String(),
          'currency': currency,
          'note': note ?? '',
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Chuyển tiền thành công',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // UC-12: Xem danh sách giao dịch
  // GET /api/transactions?month=&jar_key=&type=
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> getTransactions({
    String? month,
    String? jarKey,
    String? type,
  }) async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    try {
      final queryParams = <String, String>{};
      if (month != null && month.isNotEmpty) queryParams['month'] = month;
      if (jarKey != null && jarKey.isNotEmpty) queryParams['jar_key'] = jarKey;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: headers);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Có lỗi xảy ra',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }
}
