import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/profit_report.dart';

class ProfitReportApiException implements Exception {
  final String code;
  final String message;
  const ProfitReportApiException({required this.code, required this.message});

  @override
  String toString() => message;
}

class ProfitReportApiRepository {
  final String _initialBaseUrl;

  ProfitReportApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty
      ? ApiSettings.current.baseUrl
      : _initialBaseUrl;

  Future<ProfitReport> getReport({
    required int idSal,
    required String fromDate,
    required String toDate,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reports/profit').replace(
      queryParameters: {
        'idSal': '$idSal',
        'fromDate': fromDate,
        'toDate': toDate,
      },
    );

    late http.Response response;
    try {
      response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ProfitReportApiException(
        code: 'REQUEST_TIMEOUT',
        message: 'دریافت گزارش سود بیشتر از ۲۰ ثانیه طول کشید. اتصال API را بررسی کنید.',
      );
    } on Object catch (e) {
      throw ProfitReportApiException(
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
      throw const ProfitReportApiException(
        code: 'INVALID_RESPONSE',
        message: 'پاسخ نامعتبر از سرور دریافت شد.',
      );
    }

    final success = body['success'] == true;
    final code = body['code'] as String? ?? '';
    final message = body['message'] as String? ?? '';
    final data = body['data'];

    if (response.statusCode < 200 || response.statusCode >= 300 || !success || data is! Map<String, dynamic>) {
      throw ProfitReportApiException(
        code: code.isEmpty ? 'HTTP_${response.statusCode}' : code,
        message: message.isEmpty ? 'خطا در دریافت گزارش سود.' : message,
      );
    }

    return ProfitReport.fromJson(data);
  }
}
