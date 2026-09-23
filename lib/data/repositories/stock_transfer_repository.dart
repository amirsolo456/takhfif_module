import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/stock_transfer.dart';

class StockTransferRepository {
  final String _initialBaseUrl;

  StockTransferRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  String get baseUrl =>
      ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;

  Future<List<StockTransferWarehouse>> getWarehouses() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/stock-transfers/warehouses'))
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    _ensureSuccess(response, decoded, 'خطا در دریافت انبارها.');
    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((x) => StockTransferWarehouse.fromJson(Map<String, dynamic>.from(x)))
        .where((x) => x.id > 0 && x.name.trim().isNotEmpty)
        .toList();
  }

  Future<List<StockTransferInventory>> getInventory({
    required int idSal,
    required int sourceAnbarId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/stock-transfers/inventory').replace(
      queryParameters: {
        'idSal': '$idSal',
        'sourceAnbarId': '$sourceAnbarId',
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    final decoded = _decode(response);
    _ensureSuccess(response, decoded, 'خطا در دریافت موجودی انبار.');
    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((x) => StockTransferInventory.fromJson(Map<String, dynamic>.from(x)))
        .where((x) => x.idKala.isNotEmpty && x.stock > 0)
        .toList();
  }

  Future<List<StockTransferHistory>> getHistory({
    required int idSal,
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = Uri.parse('${baseUrl}/api/stock-transfers/history').replace(
      queryParameters: {
        'idSal': '$idSal',
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    final decoded = _decode(response);
    _ensureSuccess(response, decoded, 'خطا در دریافت تاریخچه انتقال انبار.');
    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((x) => StockTransferHistory.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }
  Future<void> createTransfer({
    required int idSal,
    required int sourceAnbarId,
    required int destinationAnbarId,
    required String sabtDate,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/stock-transfers'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'idSal': idSal,
            'sourceAnbarId': sourceAnbarId,
            'destinationAnbarId': destinationAnbarId,
            'sabtDate': sabtDate,
            'note': note,
            'items': items,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(response);
    _ensureSuccess(response, decoded, 'ثبت انتقال موجودی ناموفق بود.');
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void _ensureSuccess(http.Response response, Map<String, dynamic> decoded, String fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      throw Exception(decoded['message']?.toString() ?? fallback);
    }
  }
}
