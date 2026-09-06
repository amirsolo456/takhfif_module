import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../../core/config/kavenegar_config.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;

  String get baseUrl =>
      ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  /// Phase 1: send SMS directly from Flutter to Kavenegar.
  /// Backend log/template persistence will be added later.
  Future<SendSmsResponse> sendSms(
    String mobile,
    String message, {
    int? personId,
  }) async {
    final apiKey = KavenegarConfig.apiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception('کلید API کاوه‌نگار در تنظیمات برنامه وارد نشده است.');
    }

    final normalizedMobile = _normalizeMobile(mobile);
    if (!_isValidMobile(normalizedMobile)) {
      throw Exception('شماره موبایل مشتری معتبر نیست.');
    }

    final text = message.trim();
    if (text.isEmpty) {
      throw Exception('متن پیامک خالی است.');
    }

    // Kavenegar documents sender as optional. When it is omitted, the
    // account's defaultsender is used. When a sender is configured for this
    // build, send it explicitly so the app does not depend on the account default.
    final params = <String, String>{
      'receptor': normalizedMobile,
      'message': text,
    };

    final configuredSender = KavenegarConfig.sender.trim();
    if (configuredSender.isNotEmpty) {
      params['sender'] = configuredSender;
    }

    final uri = Uri.parse(
      '${KavenegarConfig.apiBaseUrl}/${Uri.encodeComponent(apiKey)}/sms/send.json',
    );

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: params,
          )
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw Exception('ارتباط با کاوه‌نگار برقرار نشد: $e');
    }

    if (response.body.trim().isEmpty) {
      throw Exception('کاوه‌نگار پاسخ خالی برگرداند (HTTP ${response.statusCode}).');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('پاسخ کاوه‌نگار قابل پردازش نیست: ${response.body}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('ساختار پاسخ کاوه‌نگار نامعتبر است.');
    }

    final returnNode = decoded['return'];
    if (returnNode is! Map<String, dynamic>) {
      throw Exception('بخش return در پاسخ کاوه‌نگار وجود ندارد.');
    }

    final apiStatus = _toInt(returnNode['status']);
    final apiMessage = returnNode['message']?.toString().trim();

    if (apiStatus != 200) {
      final detail = apiMessage?.isNotEmpty == true ? apiMessage! : 'خطای نامشخص';

      if (apiStatus == 412) {
        final senderHint = configuredSender.isEmpty
            ? 'خط 412 یعنی ارسال‌کننده نامعتبر است. چون sender در این بیلد تنظیم نشده، کاوه‌نگار از defaultsender حساب استفاده کرده و آن معتبر/قابل استفاده نیست. خط ارسال مجاز حساب را در Kavenegar تنظیم کنید و با --dart-define=KAVENEGAR_SENDER=YOUR_LINE بیلد بگیرید.'
            : 'خط 412 یعنی شماره ارسال‌کننده «$configuredSender» برای این حساب معتبر یا مجاز نیست.';
        throw Exception('$senderHint');
      }

      throw Exception('کاوه‌نگار: $detail (کد $apiStatus)');
    }

    String? providerMessageId;
    final entries = decoded['entries'];
    if (entries is List && entries.isNotEmpty && entries.first is Map) {
      final firstEntry = entries.first as Map;
      providerMessageId = firstEntry['messageid']?.toString();
      final entryStatusText = firstEntry['statustext']?.toString().trim();

      return SendSmsResponse(
        success: true,
        message: entryStatusText?.isNotEmpty == true
            ? entryStatusText!
            : (apiMessage?.isNotEmpty == true
                ? apiMessage!
                : 'پیامک با موفقیت به کاوه‌نگار ارسال شد.'),
        providerMessageId: providerMessageId,
      );
    }

    return SendSmsResponse(
      success: true,
      message: apiMessage?.isNotEmpty == true ? apiMessage! : 'پیامک با موفقیت ثبت شد.',
      providerMessageId: providerMessageId,
    );
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

    throw Exception('لاگ پیامک‌ها فعلاً از بک‌اند در دسترس نیست.');
  }

  static String _normalizeMobile(String mobile) {
    var digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0098')) {
      digits = '0${digits.substring(4)}';
    } else if (digits.startsWith('98') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    }

    return digits;
  }

  static bool _isValidMobile(String mobile) =>
      mobile.length == 11 && mobile.startsWith('09') && RegExp(r'^\d{11}$').hasMatch(mobile);

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
