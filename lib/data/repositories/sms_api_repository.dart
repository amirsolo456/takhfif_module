import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../../infrastructure/external_services/sms_service.dart';
import '../models/sms_model.dart';

class SmsApiRepository {
  final String _initialBaseUrl;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty
      ? ApiSettings.current.baseUrl
      : _initialBaseUrl;

  SmsApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<SendSmsResponse> sendSms(
    String mobile,
    String message, {
    int? personId,
  }) async {
    // Directly use Kavenegar SMS Service as requested
    try {
      final kavenegar = KavenegarSmsService();
      final res = await kavenegar.sendDirectSms(
        phone: mobile,
        message: message,
      );

      return SendSmsResponse(
        success: res.success,
        message: res.message,
        providerMessageId: res.messageId?.toString(),
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      throw Exception('خطا در ارسال پیامک: $cleanMsg');
    }
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    // Fetch logs directly from Kavenegar API
    try {
      final kavenegar = KavenegarSmsService();
      final latestOutbox = await kavenegar.getLatestOutbox(pageSize: 50);

      // Map Kavenegar logs to SmsLogModel
      return latestOutbox.map((e) {
        final int statusRaw = e['status'] as int? ?? 1;
        // Map Kavenegar statuses to SmsLogModel statuses
        // 10: Received by destination -> 2 (Sent)
        // 1, 2, 4, 5: Pending / Queued -> 1 (Pending)
        // Others: Failed -> 3
        int mappedStatus = 1;
        if (statusRaw == 10 || statusRaw == 200) {
          mappedStatus = 2; // Sent
        } else if (statusRaw == 1 ||
            statusRaw == 2 ||
            statusRaw == 4 ||
            statusRaw == 5) {
          mappedStatus = 1; // Pending
        } else {
          mappedStatus = 3; // Failed
        }

        final int timestamp = e['date'] as int? ?? 0;
        final date = timestamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
            : DateTime.now();

        return SmsLogModel(
          id: e['messageid'] as int? ?? 0,
          personId:
              personId, // Kavenegar doesn't have personId, we assign requested
          mobile: e['receptor']?.toString() ?? '',
          message: e['message']?.toString() ?? '',
          status: mappedStatus,
          provider: 'کاوه نگار',
          providerMessageId: e['messageid']?.toString(),
          errorMessage: mappedStatus == 3 ? e['statustext']?.toString() : null,
          createdAt: date,
        );
      }).toList();
    } catch (e) {
      debugPrint('Kavenegar SMS logs error: $e');
      return [];
    }
  }
}
