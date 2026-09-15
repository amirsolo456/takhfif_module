import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/invoice_registration.dart';

class InvoiceApiRepository {
  final String _initialBaseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  InvoiceApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<CreateInvoiceResponse> createInvoice(CreateInvoiceRequest request) async {
    final token = await _secureStorage.read(key: 'kianstore_access_token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final response = await http.post(
      Uri.parse('$baseUrl/api/invoice/full'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200) return CreateInvoiceResponse.fromJson(jsonDecode(response.body));
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'خطا در ثبت سند');
  }
}
