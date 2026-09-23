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

    Map<String, dynamic> decoded;
    try {
      final body = jsonDecode(response.body);
      decoded = body is Map<String, dynamic> ? body : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ?? 'خطا در دریافت کارکنان.',
      );
    }

    final raw = decoded['data'];
    if (raw is! List) return const <PurchaseUser>[];

    return raw
        .whereType<Map>()
        .map((item) => PurchaseUser.fromJson(Map<String, dynamic>.from(item)))
        .where((user) => user.id > 0 && user.name.trim().isNotEmpty)
        .toList(growable: false);
  }
}
