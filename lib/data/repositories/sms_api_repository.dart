import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;

  String get baseUrl =>
      ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<SmsProviderStatus> getStatus() async {
    final r = await http.get(Uri.parse('$baseUrl/api/sms/status'));
    if (r.statusCode == 200) {
      return SmsProviderStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_extractError(r, 'خطا در بررسی تنظیمات پیامک'));
  }

  Future<SendSmsResponse> sendSms(
    String mobile,
    String message, {
    int? personId,
    int? templateId,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/sms/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'message': message,
        'personId': personId,
        'templateId': templateId,
      }),
    );

    if (r.statusCode == 200) {
      return SendSmsResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }

    throw Exception(_extractError(r, 'خطا در ارسال پیامک'));
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    final uri = Uri.parse('$baseUrl/api/sms/logs').replace(
      queryParameters: personId != null ? {'personId': personId.toString()} : null,
    );
    final r = await http.get(uri);
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List<dynamic>)
          .map((e) => SmsLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(r, 'خطا در دریافت سوابق پیامک'));
  }

  String _extractError(http.Response response, String fallback) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        final message = json['message'] ?? json['error'];
        if (message is String && message.trim().isNotEmpty) return message.trim();
      }
    } catch (_) {
      // Ignore malformed error bodies and use the fallback.
    }
    return '$fallback (${response.statusCode})';
  }
}
