import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthUser {
  final int userId;
  final String userName;
  final String fullName;
  final int access;

  const AuthUser({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.access,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        userName: json['userName']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        access: (json['access'] as num?)?.toInt() ?? 0,
      );
}

class AuthRepository {
  static const _tokenKey = 'kianstore_access_token';
  static const _userIdKey = 'kianstore_user_id';
  static const _userNameKey = 'kianstore_user_name';
  static const _fullNameKey = 'kianstore_full_name';
  static const _accessKey = 'kianstore_user_access';

  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository({required this.baseUrl});

  Future<AuthUser?> login({required String username, required String password}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
          body: jsonEncode({'username': username.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode != 200 || body['success'] != true || body['data'] is! Map<String, dynamic>) {
      final message = body['message']?.toString() ?? 'نام کاربری یا رمز عبور صحیح نیست.';
      throw AuthException(message);
    }

    final data = body['data'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) throw const AuthException('توکن ورود از سرور دریافت نشد.');

    final user = AuthUser.fromJson(data);
    await _saveSession(token, user);
    return user;
  }

  Future<AuthUser?> restoreSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        await clearSession();
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['success'] != true || body['data'] is! Map<String, dynamic>) {
        await clearSession();
        return null;
      }

      final user = AuthUser.fromJson(body['data'] as Map<String, dynamic>);
      await _cacheUser(user);
      return user;
    } catch (_) {
      rethrow;
    }
  }

  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

  Future<int?> getUserId() async {
    final value = await _secureStorage.read(key: _userIdKey);
    return int.tryParse(value ?? '');
  }

  Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _userNameKey),
      _secureStorage.delete(key: _fullNameKey),
      _secureStorage.delete(key: _accessKey),
    ]);
  }

  Future<void> _saveSession(String token, AuthUser user) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _cacheUser(user);
  }

  Future<void> _cacheUser(AuthUser user) async {
    await _secureStorage.write(key: _userIdKey, value: '${user.userId}');
    await _secureStorage.write(key: _userNameKey, value: user.userName);
    await _secureStorage.write(key: _fullNameKey, value: user.fullName);
    await _secureStorage.write(key: _accessKey, value: '${user.access}');
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
