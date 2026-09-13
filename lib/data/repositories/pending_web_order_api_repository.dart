import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/pending_web_order.dart';

class PendingWebOrderApiException implements Exception {
  final String message;
  const PendingWebOrderApiException(this.message);
  @override
  String toString() => message;
}

class PendingWebOrderApiRepository {
  final String _initialBaseUrl;
  PendingWebOrderApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  Future<List<PendingWebOrder>> getPending() async {
    final response = await _request(() => http.get(
      Uri.parse('$baseUrl/api/web-orders/pending'),
      headers: const {'Accept': 'application/json'},
    ));
    final data = _data(response);
    if (data is! List) {
      throw const PendingWebOrderApiException('پاسخ سفارش‌های وب نامعتبر است.');
    }
    return data
        .map((x) => PendingWebOrder.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList();
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
    final response = await _request(() => http.post(
      Uri.parse('$baseUrl/api/web-orders/$orderNumber/finalize'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'idSal': idSal,
        'idAnbar': idAnbar,
        'idMasool': idMasool,
        'idSandogh': idSandogh,
        'idSandoghType': idSandoghType,
        // 51 is the pending state. The backend deliberately keeps the
        // document at 51 until SetFaktorFinalNew converts it to 12.
        'sanadType': sanadType,
        'sabtDate': sabtDate,
        'checkStock': true,
        'items': purchasePrices.entries
            .map((e) => {
                  'kalaId': e.key,
                  'purchasePrice': e.value,
                })
            .toList(),
      }),
    ));
    final data = _data(response);
    if (data is! Map) {
      throw const PendingWebOrderApiException('پاسخ ثبت سفارش نامعتبر است.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<http.Response> _request(Future<http.Response> Function() action) async {
    try {
      final response = await action().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        try {
          final body = jsonDecode(response.body);
          final message = body is Map ? body['message'] as String? : null;
          throw PendingWebOrderApiException(
            message ?? 'عملیات با خطای ${response.statusCode} مواجه شد.',
          );
        } on PendingWebOrderApiException {
          rethrow;
        } catch (_) {
          throw PendingWebOrderApiException(
            'عملیات با خطای ${response.statusCode} مواجه شد.',
          );
        }
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
