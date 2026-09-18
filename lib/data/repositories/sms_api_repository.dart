import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../../infrastructure/external_services/sms_service.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    return headers;
  }

  Future<SendSmsResponse> sendSms(String mobile, String message, {int? personId}) async {
    final normalizedMobile = _normalizeMobile(mobile);
    if (!_isValidMobile(normalizedMobile)) throw Exception('شماره موبایل مشتری معتبر نیست.');
    final text = message.trim();
    if (text.isEmpty) throw Exception('متن پیامک خالی است.');

    final kavenegar = KavenegarSmsService(apiKey: KavenegarSmsService.defaultApiKey);
    final response = await kavenegar.sendDirectSms(
      phone: normalizedMobile,
      message: text,
    );

    try {
      await http.post(
        Uri.parse('$baseUrl/api/sms/send'),
        headers: await _headers(json: true),
        body: jsonEncode({
          'mobile': normalizedMobile,
          'message': text,
          'personId': personId,
          'providerMessageId': response.messageId?.toString(),
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}

    return SendSmsResponse(
      success: response.success,
      message: response.message,
      providerMessageId: response.messageId?.toString(),
    );
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
    if (!_isValidMobile(normalizedMobile)) {
      throw Exception('شماره موبایل مشتری معتبر نیست ($normalizedMobile).');
    }

    final kavenegar = KavenegarSmsService(
      apiKey: KavenegarSmsService.defaultApiKey,
    );

    SmsResponse response;
    try {
      response = await kavenegar.sendLookupNotification(
        phone: normalizedMobile,
        token: '$factorNumber',
        template: 'templatemobile',
        token3: discountCode?.trim() ?? '',
      );
    } catch (e) {
      await _persistDocumentSmsStatus(
        idSal: idSal,
        idSanad: idSanad,
        smsSent: false,
      );
      rethrow;
    }

    await _persistDocumentSmsStatus(
      idSal: idSal,
      idSanad: idSanad,
      smsSent: response.success,
    );

    return OrderRegistrationSmsResponse(
      smsSent: response.success,
      status: response.success ? 'sent' : 'failed',
      statusText: response.statusText ?? response.message,
      providerMessageId: response.messageId?.toString(),
      providerStatus: response.statusCode,
      factorNumber: factorNumber,
      discountCode: discountCode,
      template: 'templatemobile',
    );
  }

  Future<void> _persistDocumentSmsStatus({
    required int idSal,
    required String idSanad,
    required bool smsSent,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sms/document-status'),
            headers: await _headers(json: true),
            body: jsonEncode({
              'idSal': idSal,
              'idSanad': idSanad,
              'smsSent': smsSent,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_extractBackendMessage(response));
      }
    } catch (e) {
      debugPrint(
        'Could not persist SMS status for sanad $idSal/$idSanad: $e',
      );
    }
  }


  Future<OrderRegistrationSmsResponse> getOrderSmsStatus({required int idSal, required String idSanad}) async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/api/sms/order-status/$idSal/${Uri.encodeComponent(idSanad)}'), headers: headers)
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
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_extractBackendMessage(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('ساختار وضعیت پیامک‌ها نامعتبر است.');
    return decoded.whereType<Map<String, dynamic>>().map(OrderRegistrationSmsStatus.fromJson).toList();
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl/api/sms/logs').replace(queryParameters: personId != null ? {'personId': personId.toString()} : null);
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.whereType<Map<String, dynamic>>().map(SmsLogModel.fromJson).toList();
    }
    throw Exception(_extractBackendMessage(response));
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
