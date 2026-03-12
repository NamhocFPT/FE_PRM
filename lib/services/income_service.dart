import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/finance_models.dart';
import 'token_storage_service.dart';

class IncomeService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/incomes';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/incomes';
    return 'http://localhost:3000/api/incomes';
  }

  Future<List<IncomeEventModel>> getIncomeHistory({String? month}) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final query = <String, String>{};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body, fallback: 'Không thể tải lịch sử thu nhập.'));
    }

    final payload = jsonDecode(response.body);
    if (payload is! List) return [];

    return payload
        .whereType<Map>()
        .map((e) => IncomeEventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<IncomeEventModel> addIncome({
    required num amount,
    required String source,
    required DateTime receivedAt,
    String note = '',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'source': source,
        'note': note,
        'received_at': receivedAt.toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractMessage(response.body, fallback: 'Không thể thêm thu nhập.'));
    }

    final payload = jsonDecode(response.body);
    final data = payload is Map && payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'])
        : <String, dynamic>{};
    return IncomeEventModel.fromJson(data);
  }

  String _extractMessage(String body, {required String fallback}) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] != null) {
        return payload['message'].toString();
      }
    } catch (_) {}
    return fallback;
  }
}
