import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/order_model.dart';
import '../models/create_order_request.dart';

class OrderApiRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  OrderApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;
  Future<OrderModel> getOrder(int id) async { final response = await http.get(Uri.parse('$baseUrl/api/orders/$id'), headers: {'Content-Type': 'application/json'}); if (response.statusCode == 200) return OrderModel.fromJson(jsonDecode(response.body)); if (response.statusCode == 404) throw Exception('سفارش مورد نظر یافت نشد'); final error = _tryDecodeError(response.body); throw Exception(error ?? 'خطا در دریافت سفارش: ${response.statusCode}'); }
  Future<OrderModel> createOrder(CreateOrderRequest request) async { final response = await http.post(Uri.parse('$baseUrl/api/orders'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson())); if (response.statusCode == 200) return OrderModel.fromJson(jsonDecode(response.body)); final error = _tryDecodeError(response.body); throw Exception(error ?? 'خطا در ثبت سفارش: ${response.statusCode}'); }
  String? _tryDecodeError(String body) { try { final data = jsonDecode(body); return data['message'] as String?; } catch (_) { return null; } }
}
