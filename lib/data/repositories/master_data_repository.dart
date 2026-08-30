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

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = _extractList(decoded);
      return data
          .map((e) => _personFromCustomerJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    throw Exception(_extractMessage(response.body) ?? 'خطا در جستجوی اشخاص');
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

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = _extractList(decoded);
      return data
          .map((e) => Kala.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    throw Exception(_extractMessage(response.body) ?? 'خطا در جستجوی کالاها');
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final payload = decoded is Map && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'])
          : Map<String, dynamic>.from(decoded);
      return _personFromCustomerJson(payload);
    }

    throw Exception(
      _extractMessage(response.body) ??
          'خطا در ثبت مشتری جدید (کد ${response.statusCode})',
    );
  }

  Person _personFromCustomerJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    final parts = name.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Person(
      id: (json['id'] as num?)?.toInt() ?? 0,
      personType: (json['idType'] as num?)?.toInt() ?? 1,
      firstName: firstName,
      lastName: lastName,
      mobile: json['mobile']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      isActive: true,
    );
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List<dynamic>;
    }
    return const [];
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString();
      }
    } catch (_) {
      // Ignore malformed/non-JSON error bodies.
    }
    return null;
  }
}
