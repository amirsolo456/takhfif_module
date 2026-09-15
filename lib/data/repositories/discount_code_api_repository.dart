import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/discount_code_model.dart';

class DiscountCodeApiRepository extends ChangeNotifier {
  final String _initialBaseUrl;
  List<DiscountCodeModel>? _allCache;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty
      ? ApiSettings.current.baseUrl
      : _initialBaseUrl;

  DiscountCodeApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  void invalidate() {
    _allCache = null;
    notifyListeners();
  }

  Future<List<DiscountCodeModel>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _allCache != null) {
      return List<DiscountCodeModel>.from(_allCache!);
    }

    final r = await http.get(Uri.parse('$baseUrl/api/discount-codes'));
    if (r.statusCode == 200) {
      final result = (jsonDecode(r.body) as List<dynamic>)
          .map((e) => DiscountCodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _allCache = List<DiscountCodeModel>.from(result);
      return result;
    }
    throw Exception('خطا در دریافت لیست کدهای تخفیف');
  }

  Future<DiscountCodeModel> create(Map<String, dynamic> data) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/discount-codes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (r.statusCode == 200) {
      final result = DiscountCodeModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
      invalidate();
      return result;
    }
    throw Exception('خطا در ایجاد کد تخفیف');
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final r = await http.put(
      Uri.parse('$baseUrl/api/discount-codes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (r.statusCode != 204) throw Exception('خطا در ویرایش کد تخفیف');
    invalidate();
  }

  Future<void> delete(int id) async {
    final r = await http.delete(Uri.parse('$baseUrl/api/discount-codes/$id'));
    if (r.statusCode != 204) throw Exception('خطا در حذف کد تخفیف');
    invalidate();
  }

  Future<ValidateDiscountCodeResponse> validate(
    String code,
    int personId,
    double orderAmount,
  ) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/discount-codes/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'personId': personId,
        'orderAmount': orderAmount,
      }),
    );
    if (r.statusCode == 200) {
      return ValidateDiscountCodeResponse.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    throw Exception('خطا در بررسی کد تخفیف');
  }

  Future<ValidateDiscountCodeResponse> consume(
    String code,
    int personId,
    double orderAmount, {
    int? idSal,
    String? idSanad,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/discount-codes/consume'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'personId': personId,
        'orderAmount': orderAmount,
        'idSal': idSal,
        'idSanad': idSanad,
      }),
    );
    if (r.statusCode == 200) {
      return ValidateDiscountCodeResponse.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    throw Exception('خطا در مصرف کد تخفیف');
  }
}
