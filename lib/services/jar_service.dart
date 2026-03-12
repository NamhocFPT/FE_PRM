import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/finance_models.dart';
import 'jarprofile_service.dart';
import 'token_storage_service.dart';

class JarService {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final JarProfileService _jarProfileService = JarProfileService();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/jars';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/jars';
    return 'http://localhost:3000/api/jars';
  }

  Future<List<JarBalanceCardModel>> getDashboardJars({DateTime? month}) async {
    final token = await _tokenStorage.getToken();
    if (token == null) throw Exception('Bạn chưa đăng nhập.');

    final activeProfile = await _jarProfileService.getActiveProfile(token);
    if (activeProfile == null) {
      throw Exception('Chưa có jar profile active. Hãy hoàn thành thiết lập 6 lọ trước.');
    }

    final targetMonth = month ?? DateTime.now();
    final jars = activeProfile['jars'];
    if (jars is! List) return [];

    final normalizedJars = jars
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final histories = await Future.wait(
      normalizedJars.map((jar) async {
        final jarName = (jar['name'] ?? '').toString();
        try {
          return await getJarHistory(jarName, token: token);
        } catch (_) {
          return <JarLedgerEntryModel>[];
        }
      }),
    );

    return List.generate(normalizedJars.length, (index) {
      final jar = normalizedJars[index];
      final entries = histories[index];

      final currentBalance = entries.fold<double>(0, (sum, item) => sum + item.delta);
      final allocatedThisMonth = entries
          .where((item) => _isSameYearMonth(item.occurredAt, targetMonth) && item.delta > 0)
          .fold<double>(0, (sum, item) => sum + item.delta);
      final spentThisMonth = entries
          .where((item) => _isSameYearMonth(item.occurredAt, targetMonth) && item.delta < 0)
          .fold<double>(0, (sum, item) => sum + item.delta.abs());

      final jarName = (jar['name'] ?? '').toString();
      return JarBalanceCardModel(
        jarKey: jarName,
        jarName: jarName,
        iconName: (jar['icon'] ?? '').toString(),
        colorHex: (jar['color'] ?? '#6366F1').toString(),
        percent: (jar['percent'] as num?)?.toDouble() ?? 0,
        currentBalance: currentBalance,
        allocatedThisMonth: allocatedThisMonth,
        spentThisMonth: spentThisMonth,
        movementCount: entries.length,
      );
    });
  }

  Future<List<JarLedgerEntryModel>> getJarHistory(String jarKey, {String? token}) async {
    token ??= await _tokenStorage.getToken();
    if (token == null) throw Exception('Bạn chưa đăng nhập.');

    final response = await http.get(
      Uri.parse('$baseUrl/${Uri.encodeComponent(jarKey)}/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body, fallback: 'Không thể tải lịch sử của lọ.'));
    }

    final payload = jsonDecode(response.body);
    if (payload is! List) return [];

    return payload
        .whereType<Map>()
        .map((e) => JarLedgerEntryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  bool _isSameYearMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

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
