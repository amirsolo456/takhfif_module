import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/purchase_user.dart';

class PurchaseUserRepository {
  final String _initialBaseUrl;

  PurchaseUserRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  String get baseUrl =>
      ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  Future<List<PurchaseUser>> getPurchaseUsers() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/users/purchase-employees'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      throw Exception(decoded['message']?.toString() ?? 'خطا در دریافت خریداران داخلی.');
    }

    final raw = decoded['data'];
    if (raw is! List) return const <PurchaseUser>[];

    return raw
        .whereType<Map>()
        .map((item) => PurchaseUser.fromJson(Map<String, dynamic>.from(item)))
        .where((user) => user.id > 0 && user.idAnbar > 0 && user.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<PurchaseUser> createPurchaseUser({required String name}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/users/purchase-employees'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'name': name.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      throw Exception(decoded['message']?.toString() ?? 'خطا در تعریف خریدار داخلی.');
    }

    final data = decoded['data'];
    if (data is! Map) throw Exception('پاسخ سرور برای خریدار داخلی معتبر نیست.');

    return PurchaseUser.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
