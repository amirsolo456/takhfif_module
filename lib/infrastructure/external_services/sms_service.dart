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

  SmsResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.rawBody,
    this.cost,
    this.messageId,
    this.receptor,
    this.statusText,
  });
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
  });

  Future<SmsResponse> sendDirectSms({
    required String phone,
    required String message,
    String? sender,
  });
}

class KavenegarSmsService implements SmsService {
  final String apiKey;
  final bool useMock;

  KavenegarSmsService({
    this.apiKey = 'YOUR_KAVENEGAR_API_KEY', // Replace with real key
    this.useMock = true, // Set to false when API key is ready
  });

  @override
  Future<SmsResponse> sendDirectSms({
    required String phone,
    required String message,
    String? sender,
  }) async {
    if (useMock || apiKey == 'YOUR_KAVENEGAR_API_KEY') {
      final mockLog = '[SMS MOCK] [DIRECT] To $phone (Sender: ${sender ?? 'Default'}): $message';
      debugPrint(mockLog);
      return SmsResponse(success: true, statusCode: 200, message: 'شبیه‌سازی موفق', rawBody: mockLog);
    }

    try {
      final url = Uri.parse('https://api.kavenegar.com/v1/$apiKey/sms/send.json');
      final Map<String, String> body = {
        'receptor': phone,
        'message': message,
      };

      // Only add sender if it is a valid virtual line (not a mobile number starting with 09)
      if (sender != null && 
          sender.trim().isNotEmpty && 
          !sender.trim().startsWith('09')) {
        body['sender'] = sender.trim();
      }

      final response = await http.post(url, body: body);

      final data = jsonDecode(response.body);
      final status = data['return']?['status'] ?? response.statusCode;
      final msg = data['return']?['message'] ?? 'Unknown API error';

      if (response.statusCode != 200) {
        throw Exception(msg);
      }

      // Parse the first entry if available
      final entries = data['entries'] as List?;
      final entry = (entries != null && entries.isNotEmpty) ? entries.first : null;

      return SmsResponse(
        success: true,
        statusCode: status,
        message: msg,
        rawBody: response.body,
        cost: entry?['cost'],
        messageId: entry?['messageid'],
        receptor: entry?['receptor'],
        statusText: entry?['statustext'],
      );
    } catch (e) {
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
  }) async {
    if (useMock || apiKey == 'YOUR_KAVENEGAR_API_KEY') {
      final mockLog = '[SMS MOCK] [LOOKUP] To $phone using template "$template". Token: $token';
      debugPrint(mockLog);
      return SmsResponse(success: true, statusCode: 200, message: 'شبیه‌سازی موفق (Lookup)', rawBody: mockLog);
    }

    try {
      final url = Uri.parse('https://api.kavenegar.com/v1/$apiKey/verify/lookup.json');
      final body = {
        'receptor': phone,
        'token': token,
        'template': template,
      };
      if (token2 != null) body['token2'] = token2;

      final response = await http.post(url, body: body);
      final data = jsonDecode(response.body);
      final status = data['return']?['status'] ?? response.statusCode;
      final msg = data['return']?['message'] ?? 'Unknown API error';

      if (response.statusCode != 200) {
        throw Exception(msg);
      }

      final entries = data['entries'] as List?;
      final entry = (entries != null && entries.isNotEmpty) ? entries.first : null;

      return SmsResponse(
        success: true,
        statusCode: status,
        message: msg,
        rawBody: response.body,
        cost: entry?['cost'],
        messageId: entry?['messageid'],
        receptor: entry?['receptor'],
        statusText: entry?['statustext'],
      );
    } catch (e) {
      debugPrint('Failed to send Lookup SMS: $e');
      rethrow;
    }
  }
}
