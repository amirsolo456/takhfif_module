import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import '../models/kala.dart';

class MasterDataRepository {
  final String baseUrl;

  MasterDataRepository({required this.baseUrl});

  String _normalize(String input) {
    return input.trim().replaceAll('ي', 'ی').replaceAll('ك', 'ک');
  }

  Future<List<Person>> searchPersons(String query) async {
    final trimmedQuery = _normalize(query);
    final uri = Uri.parse('$baseUrl/api/customers').replace(
      queryParameters: {
        if (trimmedQuery.isNotEmpty) 'search': trimmedQuery,
        'page': '1',
        'pageSize': '50',
      },
    );

    debugPrint('🔍 Searching Persons API: $uri');

    try {
      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      debugPrint('📥 Persons Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMsg = _extractMessage(response.body);
        throw Exception(serverMsg ?? 'خطای سرور (${response.statusCode})');
      }

      final decoded = _decodeObject(response.body);
      final success = decoded['success'];
      final message = decoded['message']?.toString();

      if (success is bool && !success) {
        throw Exception(message ?? 'خطا در دریافت اطلاعات اشخاص');
      }

      final data = _extractList(decoded);
      return data
          .map((e) => _personFromCustomerJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (e, stack) {
      debugPrint('❌ Exception in searchPersons: $e\n$stack');
      if (e is Exception) rethrow;
      throw Exception('ارتباط با سرور برقرار نشد: $e');
    }
  }

  Future<List<Kala>> searchKalas(String query) async {
    final trimmed = _normalize(query);
    final uri = Uri.parse('$baseUrl/api/products').replace(
      queryParameters: {
        if (trimmed.isNotEmpty) 'search': trimmed,
        'page': '1',
        'pageSize': '50',
      },
    );

    debugPrint('🔍 Searching Kalas API: $uri');

    try {
      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      debugPrint('📥 Kalas Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMsg = _extractMessage(response.body);
        throw Exception(serverMsg ?? 'خطای سرور (${response.statusCode})');
      }

      final decoded = _decodeObject(response.body);
      final success = decoded['success'];
      final message = decoded['message']?.toString();

      if (success is bool && !success) {
        throw Exception(message ?? 'خطا در دریافت اطلاعات کالاها');
      }

      final data = _extractList(decoded);
      return data
          .map((e) => Kala.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (e, stack) {
      debugPrint('❌ Exception in searchKalas: $e\n$stack');
      if (e is Exception) rethrow;
      throw Exception('ارتباط با سرور برقرار نشد: $e');
    }
  }

  Future<Person> createPerson(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/customers');
    debugPrint('➕ Creating Person API: $uri with: $data');

    try {
      final response = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      debugPrint('📥 Create Person Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMsg = _extractMessage(response.body);
        throw Exception(serverMsg ?? 'خطا در ثبت مشتری (${response.statusCode})');
      }

      final decoded = _decodeObject(response.body);
      final message = decoded['message']?.toString();

      if (decoded['success'] is bool && decoded['success'] == false) {
        throw Exception(message ?? 'خطا در ثبت مشتری جدید');
      }

      final payload = decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded;

      return _personFromCustomerJson(payload);
    } catch (e, stack) {
      debugPrint('❌ Exception in createPerson: $e\n$stack');
      if (e is Exception) rethrow;
      throw Exception('ارتباط با سرور برقرار نشد: $e');
    }
  }

  Person _personFromCustomerJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    final parts = name.isEmpty ? <String>[] : name.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Person(
      id: _toInt(json['id']),
      personType: _toInt(json['idType'], fallback: 1),
      firstName: firstName,
      lastName: lastName,
      companyName: _toInt(json['idType'], fallback: 1) == 2 ? name : null,
      mobile: json['mobile']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      isActive: true,
    );
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Response is not an object');
    } catch (_) {
      return {'data': const []};
    }
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString();
      }
    } catch (_) {}
    return null;
  }

  List<dynamic> _extractList(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is List) return data;
    if (decoded['result'] is List) return decoded['result'] as List<dynamic>;
    return const [];
  }
}
