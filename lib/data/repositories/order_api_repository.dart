import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/create_order_request.dart';

class OrderApiRepository {
  final String baseUrl;

  OrderApiRepository({required this.baseUrl});

  Future<OrderModel> getOrder(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('سفارش مورد نظر یافت نشد');
    } else {
      final error = _tryDecodeError(response.body);
      throw Exception(error ?? 'خطا در دریافت سفارش: ${response.statusCode}');
    }
  }

  Future<OrderModel> createOrder(CreateOrderRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    } else {
      final error = _tryDecodeError(response.body);
      throw Exception(error ?? 'خطا در ثبت سفارش: ${response.statusCode}');
    }
  }

  String? _tryDecodeError(String body) {
    try {
      final data = jsonDecode(body);
      return data['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
