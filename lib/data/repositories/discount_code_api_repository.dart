import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discount_code_model.dart';

class DiscountCodeApiRepository {
  final String baseUrl;

  DiscountCodeApiRepository({required this.baseUrl});

  Future<List<DiscountCodeModel>> getAll() async {
    final response = await http.get(Uri.parse('$baseUrl/api/discount-codes'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => DiscountCodeModel.fromJson(e)).toList();
    }
    throw Exception('خطا در دریافت لیست کدهای تخفیف');
  }

  Future<DiscountCodeModel> create(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/discount-codes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return DiscountCodeModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('خطا در ایجاد کد تخفیف');
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/discount-codes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 204) throw Exception('خطا در ویرایش کد تخفیف');
  }

  Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/discount-codes/$id'));
    if (response.statusCode != 204) throw Exception('خطا در حذف کد تخفیف');
  }

  Future<ValidateDiscountCodeResponse> validate(String code, int personId, double orderAmount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/discount-codes/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'personId': personId,
        'orderAmount': orderAmount,
      }),
    );
    if (response.statusCode == 200) {
      return ValidateDiscountCodeResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('خطا در بررسی کد تخفیف');
  }
}
