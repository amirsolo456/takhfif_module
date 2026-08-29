import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import '../models/kala.dart';

class MasterDataRepository {
  final String baseUrl;

  MasterDataRepository({required this.baseUrl});

  Future<List<Person>> searchPersons(String query) async {
    final uri = Uri.parse('$baseUrl/api/persons').replace(
      queryParameters: {'search': query.trim()},
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = _extractList(decoded);
      return data.map((e) => Person.fromJson(Map<String, dynamic>.from(e))).toList();
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

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = _extractList(decoded);
      return data.map((e) => Kala.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    throw Exception(_extractMessage(response.body) ?? 'خطا در جستجوی کالاها');
  }

  Future<Person> createPerson(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/persons'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final payload = decoded is Map && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'])
          : Map<String, dynamic>.from(decoded);
      return Person.fromJson(payload);
    }

    throw Exception(
      _extractMessage(response.body) ??
          'خطا در ثبت مشتری جدید (کد ${response.statusCode})',
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
