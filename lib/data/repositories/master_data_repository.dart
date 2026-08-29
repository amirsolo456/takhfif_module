import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import '../models/kala.dart';

class MasterDataRepository {
  final String baseUrl;

  MasterDataRepository({required this.baseUrl});

  Future<List<Person>> searchPersons(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/api/persons?search=$query'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Person.fromJson(e)).toList();
    }
    throw Exception('خطا در جستجوی اشخاص');
  }

  Future<List<Kala>> searchKalas(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/api/products?search=$query'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Kala.fromJson(e)).toList();
    }
    throw Exception('خطا در جستجوی کالاها');
  }

  Future<Person> createPerson(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/persons'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Person.fromJson(jsonDecode(response.body));
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'خطا در ثبت مشتری جدید (کد ${response.statusCode})');
    }
  }
}
