import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Response model returned by Kavenegar SMS Service
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

/// Helper function to convert Kavenegar HTTP status codes into readable Persian messages
String getKavenegarErrorMessage(int status, String defaultMsg) {
  switch (status) {
    case 200:
      return 'تایید شد';
    case 400:
      return 'پارامترها ناقص است';
    case 401:
      return 'حساب کاربری غیرفعال شده است';
    case 402:
      return 'عملیات ناموفق بود';
    case 403:
      return 'کد اعتبارسنجی (API Key) نامعتبر است';
    case 404:
      return 'متد مورد نظر یافت نشد';
    case 405:
      return 'فراخوانی متد با GET / POST اشتباه است';
    case 406:
      return 'پارامترهای اجباری خالی هستند';
    case 407:
      return 'دسترسی به اطلاعات مورد نظر امکان‌پذیر نیست';
    case 409:
      return 'سرور قادر به پاسخگویی نیست';
    case 411:
      return 'شماره گیرنده نامعتبر است';
    case 412:
      return 'شماره فرستنده نامعتبر است';
    case 413:
      return 'متن پیام خالی است یا طول پیام بیشتر از حد مجاز است';
    case 414:
      return 'حجم درخواست بیشتر از حد مجاز است';
    case 415:
      return 'شماره گیرنده در لیست سیاه قرار دارد';
    case 417:
      return 'شماره فرستنده اختصاصی شما نیست';
    case 418:
      return 'اعتبار ریالی حساب شما کافی نیست';
    case 419:
      return 'متن پیام حاوی کلمات غیرمجاز است';
    case 424:
      return 'الگوی مورد نظر در پنل کاوه‌نگار یافت نشد';
    case 432:
      return 'پارامتر کد (%token) در متن الگوی پیامک یافت نشد';
    case 451:
      return 'این فراخوانی بر اساس قوانین سیستم مجاز نمی‌باشد';
    default:
      return defaultMsg.isNotEmpty
          ? defaultMsg
          : 'خطای سیستم کاوه نگار ($status)';
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
  Future<List<Map<String, dynamic>>> getLatestOutbox({
    int? pageSize,
    String? sender,
  });
}

class KavenegarSmsService implements SmsService {
  /// Default official Kavenegar API key provided by the user
  static const String defaultApiKey =
      '6A596E4A70744252764A4A36546F4A75724334754C62366E436C677839653855614F63386149452F3943383D';

  final String apiKey;
  final bool useMock;

  KavenegarSmsService({String? apiKey, this.useMock = false})
    : apiKey =
          (apiKey == null ||
              apiKey.trim().isEmpty ||
              apiKey == 'YOUR_KAVENEGAR_API_KEY')
          ? defaultApiKey
          : apiKey.trim();

  @override
  Future<SmsResponse> sendDirectSms({
    required String phone,
    required String message,
    String? sender,
  }) async {
    if (useMock) {
      final mockLog =
          '[SMS MOCK] [DIRECT] To $phone (Sender: ${sender ?? 'Default'}): $message';
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
      );
    }

    try {
      final url = Uri.parse(
        'https://api.kavenegar.com/v1/$apiKey/sms/send.json',
      );
      final Map<String, String> body = {'receptor': phone, 'message': message};

      if (sender != null &&
          sender.trim().isNotEmpty &&
          !sender.trim().startsWith('09')) {
        body['sender'] = sender.trim();
      }

      final response = await http.post(url, body: body);

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'خطا در پردازش پاسخ سرور کاوه نگار (HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] as int? ?? response.statusCode;
      final rawMsg = returnObj?['message']?.toString() ?? 'Unknown API error';
      final msg = getKavenegarErrorMessage(status, rawMsg);

      if (response.statusCode != 200 || status != 200) {
        throw Exception(
          'خطای کاوه نگار [کد $status]: $msg\nپاسخ خام سرور: ${response.body}',
        );
      }

      final entries = data['entries'] as List?;
      final entry = (entries != null && entries.isNotEmpty)
          ? entries.first as Map<String, dynamic>
          : null;

      return SmsResponse(
        success: true,
        statusCode: status,
        message: msg,
        rawBody: response.body,
        cost: entry?['cost'] as int?,
        messageId: entry?['messageid'] as int?,
        receptor: entry?['receptor']?.toString(),
        statusText: entry?['statustext']?.toString(),
      );
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
    final nameText = (customerName != null && customerName.isNotEmpty)
        ? '$customerName عزیز،\n'
        : '';
    final message =
        '$nameTextکد تخفیف $code با موفقیت مصرف شد.\nمبلغ تخفیف: ${discountAmount.toInt()} تومان\nبا تشکر.';

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
      final mockLog =
          '[SMS MOCK] [LOOKUP] To $phone using template "$template". Token: $token';
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
      final url = Uri.parse(
        'https://api.kavenegar.com/v1/$apiKey/verify/lookup.json',
      );
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
        throw Exception(
          'خطا در پردازش پاسخ سرور کاوه نگار (HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] as int? ?? response.statusCode;
      final rawMsg = returnObj?['message']?.toString() ?? 'Unknown API error';
      final msg = getKavenegarErrorMessage(status, rawMsg);

      if (response.statusCode != 200 || status != 200) {
        throw Exception(
          'خطای کاوه نگار [کد $status]: $msg\nپاسخ خام سرور: ${response.body}',
        );
      }

      final entries = data['entries'] as List?;
      final entry = (entries != null && entries.isNotEmpty)
          ? entries.first as Map<String, dynamic>
          : null;

      return SmsResponse(
        success: true,
        statusCode: status,
        message: msg,
        rawBody: response.body,
        cost: entry?['cost'] as int?,
        messageId: entry?['messageid'] as int?,
        receptor: entry?['receptor']?.toString(),
        statusText: entry?['statustext']?.toString(),
      );
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
      final url = Uri.parse(
        'https://api.kavenegar.com/v1/$apiKey/account/info.json',
      );
      final response = await http.get(url);

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'خطا در پردازش پاسخ اطلاعات حساب (HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] as int? ?? response.statusCode;
      final rawMsg = returnObj?['message']?.toString() ?? 'Unknown error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception(
          'خطای کاوه نگار [کد $status]: ${getKavenegarErrorMessage(status, rawMsg)}',
        );
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
      final url = Uri.parse(
        'https://api.kavenegar.com/v1/$apiKey/sms/status.json',
      );
      final response = await http.post(
        url,
        body: {'messageid': messageId.toString()},
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'خطا در پردازش وضعیت پیامک (HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] as int? ?? response.statusCode;
      final rawMsg = returnObj?['message']?.toString() ?? 'Unknown error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception(
          'خطای کاوه نگار [کد $status]: ${getKavenegarErrorMessage(status, rawMsg)}',
        );
      }

      final entries = data['entries'] as List?;
      return (entries != null && entries.isNotEmpty)
          ? entries.first as Map<String, dynamic>
          : {};
    } catch (e) {
      debugPrint('Kavenegar Message Status Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLatestOutbox({
    int? pageSize,
    String? sender,
  }) async {
    if (useMock) {
      return [
        {
          'messageid': 100099,
          'message': 'تست (Mock)',
          'status': 10,
          'statustext': 'رسیده به گیرنده',
          'sender': '1000',
          'receptor': '09120000000',
          'date': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          'cost': 120,
        },
      ];
    }

    try {
      final url = Uri.parse(
        'https://api.kavenegar.com/v1/$apiKey/sms/latestoutbox.json',
      );
      final Map<String, String> body = {};
      if (pageSize != null) body['pagesize'] = pageSize.toString();
      if (sender != null && sender.trim().isNotEmpty)
        body['sender'] = sender.trim();

      final response = await http.post(url, body: body);

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'خطا در پردازش پاسخ لیست پیامک‌ها (HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final returnObj = data['return'];
      final status = returnObj?['status'] as int? ?? response.statusCode;
      final rawMsg = returnObj?['message']?.toString() ?? 'Unknown error';

      if (response.statusCode != 200 || status != 200) {
        throw Exception(
          'خطای کاوه نگار [کد $status]: ${getKavenegarErrorMessage(status, rawMsg)}',
        );
      }

      final entries = data['entries'] as List?;
      if (entries == null) return [];

      return entries.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Kavenegar Latest Outbox Error: $e');
      rethrow;
    }
  }
}
