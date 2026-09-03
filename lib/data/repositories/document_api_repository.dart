import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/create_document_request.dart';
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

  Future<DocumentModel> createDocument(CreateDocumentRequest request) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/documents'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    return _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت سند.');
  }

  Future<DocumentModel> getDocument({required int idSal, required String id}) async {
    final uri = Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(id)}');
    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در دریافت سند.');
  }

  Future<List<DocumentModel>> getHistory({
    required int idSal,
    int sanadType = 12,
    int page = 1,
    int pageSize = 30,
  }) async {
    final uri = Uri.parse('$baseUrl/api/documents/history').replace(
      queryParameters: {
        'idSal': '$idSal',
        'sanadType': '$sanadType',
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );

    late http.Response response;
    try {
      response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const DocumentApiException(
        code: 'REQUEST_TIMEOUT',
        message: 'دریافت تاریخچه بیشتر از ۱۵ ثانیه طول کشید. اتصال API را بررسی کنید.',
      );
    } on Object catch (e) {
      throw DocumentApiException(
        code: 'NETWORK_ERROR',
        message: 'ارتباط با API برقرار نشد: $e',
      );
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      body = decoded;
    } catch (_) {
      throw const DocumentApiException(
        code: 'INVALID_RESPONSE',
        message: 'پاسخ نامعتبر از سرور دریافت شد.',
      );
    }

    final result = DocumentHistoryApiResponse.fromJson(body);
    if (response.statusCode < 200 || response.statusCode >= 300 || !result.success) {
      throw DocumentApiException(
        code: result.code.isEmpty ? 'HTTP_${response.statusCode}' : result.code,
        message: result.message.isEmpty ? 'خطا در دریافت تاریخچه اسناد.' : result.message,
        errors: result.errors,
        warnings: result.warnings,
      );
    }

    return result.data;
  }

  DocumentModel _parseDocumentResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException('Response is not an object');
      body = decoded;
    } catch (_) {
      throw const DocumentApiException(
        code: 'INVALID_RESPONSE',
        message: 'پاسخ نامعتبر از سرور دریافت شد.',
      );
    }

    final result = DocumentApiResponse.fromJson(body);
    if (response.statusCode < 200 || response.statusCode >= 300 || !result.success || result.data == null) {
      throw DocumentApiException(
        code: result.code.isEmpty ? 'HTTP_${response.statusCode}' : result.code,
        message: result.message.isEmpty ? fallbackMessage : result.message,
        errors: result.errors,
        warnings: result.warnings,
      );
    }

    return result.data!;
  }
}
