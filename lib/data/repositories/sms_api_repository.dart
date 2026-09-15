import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<SendSmsResponse> sendSms(String mobile, String message, {int? personId}) async {
    final normalizedMobile = _normalizeMobile(mobile);
    if (!_isValidMobile(normalizedMobile)) throw Exception('شماره موبایل مشتری معتبر نیست.');
    final text = message.trim();
    if (text.isEmpty) throw Exception('متن پیامک خالی است.');
    final response = await http.post(
      Uri.parse('$baseUrl/api/sms/send'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'mobile': normalizedMobile, 'message': text, 'personId': personId}),
    ).timeout(const Duration(seconds: 20));
    return _parseResponse(response);
  }

  Future<OrderRegistrationSmsResponse> sendOrderRegistrationSms({
    required int idSal,
    required String idSanad,
    required int personId,
    required String mobile,
    required int factorNumber,
    String? discountCode,
  }) async {
    final normalizedMobile = _normalizeMobile(mobile);
    if (!_isValidMobile(normalizedMobile)) throw Exception('شماره موبایل مشتری معتبر نیست.');
    final response = await http.post(
      Uri.parse('$baseUrl/api/sms/order-registration'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'idSal': idSal,
        'idSanad': idSanad,
        'personId': personId,
        'mobile': normalizedMobile,
        'factorNumber': factorNumber,
        if (discountCode != null && discountCode.trim().isNotEmpty) 'discountCode': discountCode.trim(),
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractBackendMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('پاسخ سرویس پیامک نامعتبر است.');
    return OrderRegistrationSmsResponse.fromJson(decoded);
  }

  Future<OrderRegistrationSmsResponse> getOrderSmsStatus({required int idSal, required String idSanad}) async {
    final response = await http.get(Uri.parse('$baseUrl/api/sms/order-status/$idSal/${Uri.encodeComponent(idSanad)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_extractBackendMessage(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('پاسخ وضعیت پیامک نامعتبر است.');
    return OrderRegistrationSmsResponse.fromJson(decoded);
  }

  Future<List<OrderRegistrationSmsStatus>> getOrderSmsStatuses({
    required int idSal,
    required int sanadType,
    required int page,
    required int pageSize,
  }) async {
    final uri = Uri.parse('$baseUrl/api/sms/order-statuses').replace(queryParameters: {
      'idSal': '$idSal', 'sanadType': '$sanadType', 'page': '$page', 'pageSize': '$pageSize'
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_extractBackendMessage(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('ساختار وضعیت پیامک‌ها نامعتبر است.');
    return decoded.whereType<Map<String, dynamic>>().map(OrderRegistrationSmsStatus.fromJson).toList();
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    final uri = Uri.parse('$baseUrl/api/sms/logs').replace(queryParameters: personId != null ? {'personId': personId.toString()} : null);
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.whereType<Map<String, dynamic>>().map(SmsLogModel.fromJson).toList();
    }
    throw Exception(_extractBackendMessage(response));
  }

  SendSmsResponse _parseResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_extractBackendMessage(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('پاسخ سرویس پیامک نامعتبر است.');
    return SendSmsResponse.fromJson(decoded);
  }

  String _extractBackendMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? decoded['title'] ?? decoded['detail'] ?? 'خطا در سرویس پیامک').toString();
      }
    } catch (_) {}
    return 'خطا در سرویس پیامک (HTTP ${response.statusCode})';
  }

  static String _normalizeMobile(String mobile) {
    var digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0098')) digits = '0${digits.substring(4)}';
    else if (digits.startsWith('98') && digits.length == 12) digits = '0${digits.substring(2)}';
    return digits;
  }

  static bool _isValidMobile(String mobile) => mobile.length == 11 && mobile.startsWith('09') && RegExp(r'^\d{11}$').hasMatch(mobile);
}
