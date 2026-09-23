import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/purchase_employee.dart';

class PurchaseEmployeeRepository {
  final String _initialBaseUrl;
  PurchaseEmployeeRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  Future<List<PurchaseEmployee>> getAll({bool activeOnly = true}) async {
    final uri = Uri.parse('$baseUrl/api/purchase-employees').replace(queryParameters: {'activeOnly': '$activeOnly'});
    final response = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      throw Exception(decoded['message']?.toString() ?? 'خطا در دریافت کارکنان خرید.');
    }
    final raw = decoded['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => PurchaseEmployee.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<PurchaseEmployee> create({required String name, String? mobile}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/purchase-employees'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name.trim(), 'mobile': mobile?.trim()}),
    ).timeout(const Duration(seconds: 15));
    return _parseEmployee(response, 'خطا در ثبت کارمند خرید.');
  }

  Future<PurchaseEmployee> update({required int id, required String name, String? mobile, bool? isActive}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/purchase-employees/$id'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name.trim(), 'mobile': mobile?.trim(), if (isActive != null) 'isActive': isActive}),
    ).timeout(const Duration(seconds: 15));
    return _parseEmployee(response, 'خطا در ویرایش کارمند خرید.');
  }

  Future<void> disable(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/purchase-employees/$id'), headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      throw Exception(decoded['message']?.toString() ?? 'خطا در غیرفعال کردن کارمند خرید.');
    }
  }

  PurchaseEmployee _parseEmployee(http.Response response, String fallback) {
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) throw Exception(decoded['message']?.toString() ?? fallback);
    final data = decoded['data'];
    if (data is! Map) throw Exception(fallback);
    return PurchaseEmployee.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) { return <String, dynamic>{}; }
  }
}
