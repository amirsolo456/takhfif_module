import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SmsResponse {
  final bool success;
  final int statusCode;
  final String message;
  final String rawBody;
  final int? cost;
  final int? messageId;
  final String? receptor;
  final String? statusText;
  final String? sender;
  final int? date;

  SmsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.rawBody,
    this.cost,
    this.messageId,
    this.receptor,
    this.statusText,
    this.sender,
    this.date,
  });

  factory SmsResponse.fromJson(Map<String, dynamic> json, int httpStatusCode, String rawBody) {
    final returnObj = json['return'];
    final status = returnObj?['status'] ?? httpStatusCode;
    final msg = returnObj?['message'] ?? 'Unknown API error';
    
    final entries = json['entries'];
    Map<String, dynamic>? entry;
    if (entries is List && entries.isNotEmpty) {
      if (entries.first is Map<String, dynamic>) {
        entry = entries.first as Map<String, dynamic>;
      }
    } else if (entries is Map<String, dynamic>) {
      entry = entries;
    }

    int? parseToInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    return SmsResponse(
      success: status == 200,
      statusCode: status,
      message: msg,
      rawBody: rawBody,
      cost: parseToInt(entry?['cost']),
      messageId: parseToInt(entry?['messageid']),
      receptor: entry?['receptor']?.toString(),
      statusText: entry?['statustext']?.toString() ?? entry?['status']?.toString(),
      sender: entry?['sender']?.toString(),
      date: parseToInt(entry?['date']),
    );
  }
}

abstract class SmsService {
  Future<SmsResponse> sendConsumptionNotification({
    required String phone,
    required String code,
    required double discountAmount,
    String? customerName,
    String? sender,
  });

  Future<SmsResponse> sendLookupNotification({
    required String phone,
    required String token,
    required String template,
    String? token2,
    String? token3,
  });

  Future<SmsResponse> sendDirectSms({
    required String phone,
    required String message,
    String? sender,
  });

  Future<Map<String, dynamic>> getAccountInfo();
  Future<Map<String, dynamic>> getMessageStatus(int messageId);
  Future<SmsResponse> cancelMessage(int messageId);
  Future<List<dynamic>> getInboxMessages({String? line, int? isRead});
}

class KavenegarSmsService implements SmsService {
  static const String defaultApiKey = '6A596E4A70744252764A4A36546F4A75724334754C62366E436C677839653855614F63386149452F3943383D';
  
  final String apiKey;
  final bool useMock;

  KavenegarSmsService({
    String? apiKey,
    this.useMock = false,
  }) : apiKey = (apiKey == null || apiKey.trim().isEmpty || apiKey == 'YOUR_KAVENEGAR_API_KEY')
            ? defaultApiKey
            : apiKey.trim();

  String _baseUrl(String controller, String method) {
    return 'https://api.kavenegar.com/v1/$apiKey/$controller/$method.json';
  }

  @override
  Future<SmsResponse> sendDirectSms({
    required String phone,
    required String message,
    String? sender,
  }) async {
    if (useMock) {
      final mockLog = '[SMS MOCK] [DIRECT] To $phone (Sender: ${sender ?? 'Default'}): $message';
      debugPrint(mockLog);
      return SmsResponse(
        success: true,
        statusCode: 200,
        message: 'شبیه‌سازی موفق (Mock Mode)',
        rawBody: mockLog,
        cost: 120,
        messageId: 100099,
        receptor: phone,
        statusText: 'ارسال شد (Mock)',
        sender: sender,
      );
    }

    try {
      final url = Uri.parse(_baseUrl('sms', 'send'));
      final Map<String, String> body = {
        'receptor': phone,
        'message': message,
      };

      if (sender != null && sender.trim().isNotEmpty) {
        body['sender'] = sender.trim();
      }

      final response = await http.post(url, body: body);

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('خطا در پردازش پاسخ سرور کاوه نگار (HTTP ${response.statusCode}): ${response.body}');
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] ?? response.statusCode;
      final msg = returnObj?['message'] ?? 'Unknown API error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception('خطای کاوه نگار [کد $status]: $msg\nپاسخ خام سرور: ${response.body}');
      }

      return SmsResponse.fromJson(data, response.statusCode, response.body);
    } catch (e) {
      debugPrint('Kavenegar SMS Send Error: $e');
      rethrow;
    }
  }

  @override
  Future<SmsResponse> sendConsumptionNotification({
    required String phone,
    required String code,
    required double discountAmount,
    String? customerName,
    String? sender,
  }) async {
    final nameText = (customerName != null && customerName.isNotEmpty) ? '$customerName عزیز،\n' : '';
    final message = '$nameTextکد تخفیف $code با موفقیت مصرف شد.\nمبلغ تخفیف: ${discountAmount.toInt()} تومان\nبا تشکر.';

    return await sendDirectSms(phone: phone, message: message, sender: sender);
  }

  @override
  Future<SmsResponse> sendLookupNotification({
    required String phone,
    required String token,
    required String template,
    String? token2,
    String? token3,
  }) async {
    if (useMock) {
      final mockLog = '[SMS MOCK] [LOOKUP] To $phone using template "$template". Token: $token';
      debugPrint(mockLog);
      return SmsResponse(
        success: true,
        statusCode: 200,
        message: 'شبیه‌سازی موفق (Lookup Mock)',
        rawBody: mockLog,
        cost: 120,
        messageId: 100100,
        receptor: phone,
        statusText: 'ارسال شد (Mock Lookup)',
      );
    }

    try {
      final url = Uri.parse(_baseUrl('verify', 'lookup'));
      final Map<String, String> body = {
        'receptor': phone,
        'token': token,
        'template': template,
      };
      if (token2 != null && token2.isNotEmpty) body['token2'] = token2;
      if (token3 != null && token3.isNotEmpty) body['token3'] = token3;

      final response = await http.post(url, body: body);
      
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('خطا در پردازش پاسخ سرور کاوه نگار (HTTP ${response.statusCode}): ${response.body}');
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] ?? response.statusCode;
      final msg = returnObj?['message'] ?? 'Unknown API error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception('خطای کاوه نگار [کد $status]: $msg\nپاسخ خام سرور: ${response.body}');
      }

      return SmsResponse.fromJson(data, response.statusCode, response.body);
    } catch (e) {
      debugPrint('Kavenegar Lookup SMS Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getAccountInfo() async {
    if (useMock) {
      return {
        'remaincredit': 2500000,
        'expiredate': 1767225600,
        'type': 'DL (Mock)',
      };
    }

    try {
      final url = Uri.parse(_baseUrl('account', 'info'));
      final response = await http.get(url);
      
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('خطا در پردازش پاسخ اطلاعات حساب (HTTP ${response.statusCode}): ${response.body}');
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] ?? response.statusCode;
      final msg = returnObj?['message'] ?? 'Unknown error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception('خطای کاوه نگار [کد $status]: $msg');
      }

      return data['entries'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('Kavenegar Account Info Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMessageStatus(int messageId) async {
    if (useMock) {
      return {
        'messageid': messageId,
        'status': 1,
        'statustext': 'ارسال به مخابرات (Mock)',
      };
    }

    try {
      final url = Uri.parse(_baseUrl('sms', 'status'));
      final response = await http.post(url, body: {'messageid': messageId.toString()});

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('خطا در پردازش وضعیت پیامک (HTTP ${response.statusCode}): ${response.body}');
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] ?? response.statusCode;
      final msg = returnObj?['message'] ?? 'Unknown error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception('خطای کاوه نگار [کد $status]: $msg');
      }

      final entries = data['entries'] as List?;
      return (entries != null && entries.isNotEmpty && entries.first is Map<String, dynamic>) 
          ? entries.first as Map<String, dynamic> 
          : {};
    } catch (e) {
      debugPrint('Kavenegar Message Status Error: $e');
      rethrow;
    }
  }

  @override
  Future<SmsResponse> cancelMessage(int messageId) async {
    if (useMock) {
      return SmsResponse(
        success: true,
        statusCode: 200,
        message: 'لغو موفق (Mock)',
        rawBody: 'Mock cancel',
        messageId: messageId,
        statusText: 'لغو شد',
      );
    }

    try {
      final url = Uri.parse(_baseUrl('sms', 'cancel'));
      final response = await http.post(url, body: {'messageid': messageId.toString()});
      
      Map<String, dynamic> data = jsonDecode(response.body);
      return SmsResponse.fromJson(data, response.statusCode, response.body);
    } catch (e) {
      debugPrint('Kavenegar Cancel Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getInboxMessages({String? line, int? isRead}) async {
    if (useMock) {
      return [];
    }

    try {
      final url = Uri.parse(_baseUrl('sms', 'receive'));
      final Map<String, String> body = {};
      if (line != null) body['line'] = line;
      if (isRead != null) body['isread'] = isRead.toString();

      final response = await http.post(url, body: body);
      final data = jsonDecode(response.body);
      return data['entries'] as List<dynamic>? ?? [];
    } catch (e) {
      debugPrint('Kavenegar Inbox Error: $e');
      rethrow;
    }
  }
}
