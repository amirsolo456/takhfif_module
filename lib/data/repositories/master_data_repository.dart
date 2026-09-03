import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import '../models/kala.dart';

class MasterDataRepository {
  final String baseUrl;

  MasterDataRepository({required this.baseUrl});

  Future<List<Person>> searchPersons(String query) async {
    final uri = Uri.parse('$baseUrl/api/customers').replace(
      queryParameters: {
        'search': query.trim(),
        'page': '1',
        'pageSize': '50',
      },
    );

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    final decoded = _decodeObject(response.body);
    final success = decoded['success'];
    final message = decoded['message']?.toString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(message ?? 'خطا در جستجوی اشخاص (کد ${response.statusCode})');
    }

    if (success is bool && !success) {
      throw Exception(message ?? 'خطا در جستجوی اشخاص');
    }

    final data = _extractList(decoded);
    return data
        .map((e) => _personFromCustomerJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<List<Kala>> searchKalas(String query) async {
    final trimmed = query.trim();
    final uri = Uri.parse('$baseUrl/api/products').replace(
      queryParameters: {
        if (trimmed.isNotEmpty) 'search': trimmed,
        'page': '1',
        'pageSize': '50',
      },
    );

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    final decoded = _decodeObject(response.body);
    final success = decoded['success'];
    final message = decoded['message']?.toString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(message ?? 'خطا در جستجوی کالاها (کد ${response.statusCode})');
    }

    if (success is bool && !success) {
      throw Exception(message ?? 'خطا در جستجوی کالاها');
    }

    final data = _extractList(decoded);
    return data
        .map((e) => Kala.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<Person> createPerson(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/customers'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    final decoded = _decodeObject(response.body);
    final message = decoded['message']?.toString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        message ?? 'خطا در ثبت مشتری جدید (کد ${response.statusCode})',
      );
    }

    if (decoded['success'] is bool && decoded['success'] == false) {
      throw Exception(message ?? 'خطا در ثبت مشتری جدید');
    }

    final payload = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : decoded;

    return _personFromCustomerJson(payload);
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
      throw Exception('پاسخ نامعتبر از سرور دریافت شد.');
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is List) return data;
    if (decoded is Map && decoded['result'] is List) return decoded['result'] as List<dynamic>;
    return const [];
  }
}
