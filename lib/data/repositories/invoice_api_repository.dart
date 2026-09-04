import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/invoice_registration.dart';

class InvoiceApiRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  InvoiceApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<CreateInvoiceResponse> createInvoice(CreateInvoiceRequest request) async {
    final response = await http.post(Uri.parse('$baseUrl/api/invoice/full'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson()));
    if (response.statusCode == 200) return CreateInvoiceResponse.fromJson(jsonDecode(response.body));
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'خطا در ثبت سند');
  }
}
