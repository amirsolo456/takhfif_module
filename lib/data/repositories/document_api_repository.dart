import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/document_model.dart';

class DocumentApiException implements Exception {
  final String code;
  final String message;
  final dynamic errors;
  final dynamic warnings;

  const DocumentApiException({
    required this.code,
    required this.message,
    this.errors,
    this.warnings,
  });

  @override
  String toString() => message;
}

class DocumentApiRepository {
  final String baseUrl;

  const DocumentApiRepository({required this.baseUrl});

  Future<DocumentModel> getDocument({required int idSal, required String id}) async {
    final uri = Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(id)}');

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw DocumentApiException(
        code: 'INVALID_RESPONSE',
        message: 'پاسخ نامعتبر از سرور دریافت شد.',
      );
    }

    final result = DocumentApiResponse.fromJson(body);

    if (response.statusCode < 200 || response.statusCode >= 300 || !result.success || result.data == null) {
      throw DocumentApiException(
        code: result.code.isEmpty ? 'HTTP_${response.statusCode}' : result.code,
        message: result.message.isEmpty ? 'خطا در دریافت سند.' : result.message,
        errors: result.errors,
        warnings: result.warnings,
      );
    }

    return result.data!;
  }
}
