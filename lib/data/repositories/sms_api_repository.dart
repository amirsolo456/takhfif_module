import 'dart:async';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final userId = await _secureStorage.read(key: 'kianstore_user_id');
    if (userId != null && userId.isNotEmpty) headers['X-User-Id'] = userId;
    return headers;
  }

  Future<http.Response> _request(Future<http.Response> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('ارتباط با سرور پیامک بیشتر از ۲۰ ثانیه طول کشید.');
    } catch (e) {
      throw Exception('ارتباط با سرور پیامک برقرار نشد: $e');
    }
  }

  Future<SendSmsResponse> sendSms(String mobile, String message, {int? personId}) async {
    final normalizedMobile = _normalizeMobile(mobile);
    if (!_isValidMobile(normalizedMobile)) throw Exception('شماره موبایل مشتری معتبر نیست.');
    final text = message.trim();
    if (text.isEmpty) throw Exception('متن پیامک خالی است.');
    final response = await _request(() => http.post(
      Uri.parse('$baseUrl/api/sms/send'),
      headers: await _headers(json: true),
      body: jsonEncode({'mobile': normalizedMobile, 'message': text, 'personId': personId}),
    ));
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
    final response = await _request(() => http.post(
      Uri.parse('$baseUrl/api/sms/order-registration'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'idSal': idSal,
        'idSanad': idSanad,
        'personId': personId,
        'mobile': normalizedMobile,
        'factorNumber': factorNumber,
        if (discountCode != null && discountCode.trim().isNotEmpty) 'discountCode': discountCode.trim(),
      }),
    ));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractBackendMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('پاسخ سرویس پیامک نامعتبر است.');
    return OrderRegistrationSmsResponse.fromJson(decoded);
  }

  Future<OrderRegistrationSmsResponse> getOrderSmsStatus({required int idSal, required String idSanad}) async {
    final headers = await _headers();
    final response = await _request(() => http.get(Uri.parse('$baseUrl/api/sms/order-status/$idSal/${Uri.encodeComponent(idSanad)}'), headers: headers));
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
    final headers = await _headers();
    final queryParams = <String, String>{
      'sanadType': '$sanadType',
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (idSal > 0) {
      queryParams['idSal'] = '$idSal';
    }
    final uri = Uri.parse('$baseUrl/api/sms/order-statuses').replace(queryParameters: queryParams);
    final response = await _request(() => http.get(uri, headers: headers));
    if (response.statusCode != 200) throw Exception(_extractBackendMessage(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('ساختار وضعیت پیامک‌ها نامعتبر است.');
    return decoded.whereType<Map<String, dynamic>>().map(OrderRegistrationSmsStatus.fromJson).toList();
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl/api/sms/logs').replace(queryParameters: personId != null ? {'personId': personId.toString()} : null);
    final response = await _request(() => http.get(uri, headers: headers));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.whereType<Map<String, dynamic>>().map(SmsLogModel.fromJson).toList();
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        final data = decoded['data'] as List;
        return data.whereType<Map<String, dynamic>>().map(SmsLogModel.fromJson).toList();
      }
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
    if (digits.startsWith('0098')) {
      digits = '0${digits.substring(4)}';
    } else {
      if (digits.startsWith('98') && digits.length == 12) {
        digits = '0${digits.substring(2)}';
      }
    }
    return digits;
  }

  static bool _isValidMobile(String mobile) => mobile.length == 11 && mobile.startsWith('09') && RegExp(r'^\d{11}$').hasMatch(mobile);
}
