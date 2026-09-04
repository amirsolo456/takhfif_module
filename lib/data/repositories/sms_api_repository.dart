import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;

  String get baseUrl =>
      ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<SendSmsResponse> sendSms(
    String mobile,
    String message, {
    int? personId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sms/send'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'message': message,
        'personId': personId,
      }),
    );

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {
      // Non-JSON error responses are handled below.
    }

    if (body != null) {
      final apiMessage = body['message']?.toString().trim();
      final success = body['success'] == true;

      if (response.statusCode == 200 && success) {
        return SendSmsResponse.fromJson(body);
      }

      if (apiMessage != null && apiMessage.isNotEmpty) {
        throw Exception(apiMessage);
      }
    }

    final raw = response.body.trim();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        raw.isNotEmpty
            ? 'خطای سرور (${response.statusCode}): $raw'
            : 'خطا در ارسال پیامک (${response.statusCode})',
      );
    }

    throw Exception('ارسال پیامک ناموفق بود.');
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    final uri = Uri.parse('$baseUrl/api/sms/logs').replace(
      queryParameters: personId != null ? {'personId': personId.toString()} : null,
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(SmsLogModel.fromJson)
            .toList();
      }
    }

    throw Exception('خطا در دریافت لاگ‌های پیامک');
  }
}
