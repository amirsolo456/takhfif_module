import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice_registration.dart';

class InvoiceApiRepository {
  final String baseUrl;

  InvoiceApiRepository({required this.baseUrl});

  Future<CreateInvoiceResponse> createInvoice(CreateInvoiceRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/invoice/full'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return CreateInvoiceResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در ثبت سند');
    }
  }
}
