import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  // Singleton pattern
  static final TokenStorageService _instance = TokenStorageService._internal();
  factory TokenStorageService() => _instance;
  TokenStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // Lưu token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Lấy token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Xóa token (dùng khi logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Kiểm tra có token hay không
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
