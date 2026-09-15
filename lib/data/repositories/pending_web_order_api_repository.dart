import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/pending_web_order.dart';

class PendingWebOrderApiException implements Exception {
  final String message;
  const PendingWebOrderApiException(this.message);
  @override
  String toString() => message;
}

class PendingWebOrderApiRepository extends ChangeNotifier {
  final String _initialBaseUrl;
  List<PendingWebOrder>? _pendingCache;

  PendingWebOrderApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  void invalidatePending() {
    _pendingCache = null;
    notifyListeners();
  }

  Future<List<PendingWebOrder>> getPending({bool forceRefresh = false}) async {
    if (!forceRefresh && _pendingCache != null) {
      return List<PendingWebOrder>.from(_pendingCache!);
    }

    final response = await _request(() => http.get(
      Uri.parse('$baseUrl/api/web-orders/pending'),
      headers: const {'Accept': 'application/json'},
    ));
    final data = _data(response);
    if (data is! List) {
      throw const PendingWebOrderApiException('پاسخ سفارش‌های وب نامعتبر است.');
    }
    final result = data
        .map((x) => PendingWebOrder.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList();
    _pendingCache = List<PendingWebOrder>.from(result);
    return result;
  }

  Future<Map<String, dynamic>> finalizeOrder({
    required String orderNumber,
    required int idSal,
    required int idAnbar,
    required int idMasool,
    required int idSandogh,
    required int idSandoghType,
    required String sabtDate,
    required Map<String, double> purchasePrices,
    int sanadType = 51,
  }) async {
    final payload = <String, dynamic>{
      'idSal': idSal,
      'idAnbar': idAnbar,
      'idMasool': idMasool,
      'idSandogh': idSandogh,
      'idSandoghType': idSandoghType,
      'sanadType': sanadType,
      'checkStock': true,
      'items': purchasePrices.entries
          .map((e) => {
                'kalaId': e.key,
                'purchasePrice': e.value,
              })
          .toList(),
    };

    if (sabtDate.trim().isNotEmpty) {
      payload['sabtDate'] = sabtDate.trim();
    }

    final response = await _request(() => http.post(
      Uri.parse('$baseUrl/api/web-orders/$orderNumber/finalize'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    ));

    final data = _data(response);
    if (data is! Map) {
      throw const PendingWebOrderApiException('پاسخ ثبت سفارش نامعتبر است.');
    }
    invalidatePending();
    return Map<String, dynamic>.from(data);
  }

  Future<http.Response> _request(Future<http.Response> Function() action) async {
    try {
      final response = await action().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            final message = body['message'];
            if (message is String && message.trim().isNotEmpty) {
              throw PendingWebOrderApiException(message);
            }

            final errors = body['errors'];
            if (errors is Map) {
              final messages = <String>[];
              for (final entry in errors.entries) {
                final value = entry.value;
                if (value is List) {
                  messages.addAll(value.whereType<String>());
                } else if (value is String) {
                  messages.add(value);
                }
              }
              if (messages.isNotEmpty) {
                throw PendingWebOrderApiException(messages.join('\n'));
              }
            }
          }
        } on PendingWebOrderApiException {
          rethrow;
        } catch (_) {}

        throw PendingWebOrderApiException(
          'عملیات با خطای ${response.statusCode} مواجه شد.',
        );
      }
      return response;
    } on TimeoutException {
      throw const PendingWebOrderApiException(
        'ارتباط با سرور بیشتر از ۲۰ ثانیه طول کشید.',
      );
    } on PendingWebOrderApiException {
      rethrow;
    } catch (e) {
      throw PendingWebOrderApiException('ارتباط با API برقرار نشد: $e');
    }
  }

  dynamic _data(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['success'] != true) {
      final message = decoded is Map ? decoded['message'] as String? : null;
      throw PendingWebOrderApiException(message ?? 'عملیات ناموفق بود.');
    }
    return decoded['data'];
  }
}
