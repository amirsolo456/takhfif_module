import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/create_document_request.dart';
import '../models/document_model.dart';

class DocumentApiException implements Exception {
  final String code;
  final String message;
  final dynamic errors;
  final dynamic warnings;
  const DocumentApiException({required this.code, required this.message, this.errors, this.warnings});
  @override
  String toString() => message;
}

class _HistoryCacheEntry {
  final List<DocumentModel> data;
  _HistoryCacheEntry(this.data);
}

class DocumentApiRepository extends ChangeNotifier {
  final String _initialBaseUrl;
  final Map<String, _HistoryCacheEntry> _historyCache = <String, _HistoryCacheEntry>{};
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  int _revision = 0;

  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  int get revision => _revision;
  DocumentApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<Map<String, String>> _headers({required bool json}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final userId = await _secureStorage.read(key: 'kianstore_user_id');
    if (userId != null && userId.isNotEmpty) headers['X-User-Id'] = userId;
    return headers;
  }

  void invalidateHistory() { _historyCache.clear(); _revision++; notifyListeners(); }

  Future<DocumentModel> createDocument(CreateDocumentRequest request) async {
    final response = await http.post(Uri.parse('$baseUrl/api/documents'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 20));
    final document = _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت سند.');
    invalidateHistory();
    return document;
  }

  Future<DocumentModel> createPurchaseDocument({required CreateDocumentRequest request}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/documents/purchase'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 30));
    final document = _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت سند خرید.');
    invalidateHistory();
    return document;
  }

  Future<DocumentModel> deletePurchaseDocument({required int idSal, required String id}) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/documents/purchase/$idSal/${Uri.encodeComponent(id)}'), headers: await _headers(json: false)).timeout(const Duration(seconds: 30));
    final document = _parseDocumentResponse(response, fallbackMessage: 'خطا در حذف سند خرید.');
    invalidateHistory();
    return document;
  }

  Future<DocumentModel> createPartnerSaleDocument({required CreateDocumentRequest request}) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/documents/partner-sale'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 30));
      if (response.statusCode == 404 || response.statusCode == 405) return createDocument(request);
      final document = _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت فروش از انبار همکار.');
      invalidateHistory();
      return document;
    } catch (e) {
      if (e is DocumentApiException) rethrow;
      try { return await createDocument(request); } catch (_) { throw DocumentApiException(code: 'CREATE_PARTNER_SALE_ERROR', message: 'خطا در ثبت فروش از انبار همکار: $e'); }
    }
  }

  Future<DocumentModel> updatePartnerSaleDocument({required int idSal, required String id, required CreateDocumentRequest request}) async {
    final response = await http.put(Uri.parse('$baseUrl/api/documents/partner-sale/$idSal/${Uri.encodeComponent(id)}'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 30));
    final document = _parseDocumentResponse(response, fallbackMessage: 'خطا در ویرایش فروش از انبار همکار.');
    invalidateHistory();
    return document;
  }

  Future<bool> deletePartnerSaleDocument({required int idSal, required String id}) async => deleteDocument(idSal: idSal, id: id, sanadType: 113);

  Future<bool> updateSaleDocument({required int idSal, required String id, required List<Map<String, dynamic>> items}) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) throw const DocumentApiException(code: 'INVALID_ID', message: 'شناسه سند نامعتبر است.');
    final headers = await _headers(json: true);
    final body = jsonEncode({'idSal': idSal, 'id': cleanId, 'items': items});

    final endpoints = <Uri>[
      Uri.parse('$baseUrl/api/documents/sale/$idSal/${Uri.encodeComponent(cleanId)}'),
      Uri.parse('$baseUrl/api/documents/sale/${Uri.encodeComponent(cleanId)}'),
      Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(cleanId)}'),
      Uri.parse('$baseUrl/api/documents/${Uri.encodeComponent(cleanId)}'),
    ];

    String lastErrorMessage = 'خطا در ویرایش سند فروش.';
    for (final uri in endpoints) {
      try {
        final response = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 20));
        if (response.statusCode >= 200 && response.statusCode < 300) { invalidateHistory(); return true; }
        if (response.statusCode != 404 && response.statusCode != 405) {
          throw DocumentApiException(code: 'HTTP_${response.statusCode}', message: _extractMessage(response.body, lastErrorMessage));
        }
      } catch (e) {
        if (e is DocumentApiException) rethrow;
        lastErrorMessage = e.toString();
      }
    }

    try {
      final response = await http.post(Uri.parse('$baseUrl/api/documents/sale/update'), headers: headers, body: body).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) { invalidateHistory(); return true; }
    } catch (_) {}

    throw DocumentApiException(code: 'UPDATE_FAILED', message: lastErrorMessage);
  }

  Future<bool> deleteSaleDocument({required int idSal, required String id, String? password}) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) throw const DocumentApiException(code: 'INVALID_ID', message: 'شناسه سند نامعتبر است.');
    final headers = await _headers(json: true);
    final cleanPassword = password?.trim();
    final bodyMap = <String, dynamic>{'idSal': idSal, 'id': cleanId};
    if (cleanPassword != null && cleanPassword.isNotEmpty) {
      bodyMap['password'] = cleanPassword;
    }
    final body = jsonEncode(bodyMap);

    final endpoints = <Uri>[
      Uri.parse('$baseUrl/api/documents/sale/$idSal/${Uri.encodeComponent(cleanId)}'),
      Uri.parse('$baseUrl/api/documents/sale/${Uri.encodeComponent(cleanId)}'),
      Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(cleanId)}'),
      Uri.parse('$baseUrl/api/documents/${Uri.encodeComponent(cleanId)}'),
    ];

    String lastErrorMessage = 'خطا در حذف سند فروش.';
    for (final uri in endpoints) {
      try {
        final response = await http.delete(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          invalidateHistory();
          return true;
        }
        if (response.statusCode != 404 && response.statusCode != 405) {
          throw DocumentApiException(
            code: _extractCode(response.body, 'HTTP_${response.statusCode}'),
            message: _extractMessage(response.body, lastErrorMessage),
          );
        }
      } catch (e) {
        if (e is DocumentApiException) rethrow;
        lastErrorMessage = e.toString();
      }
    }

    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/documents/sale/delete'), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateHistory();
        return true;
      }
    } catch (_) {}

    throw DocumentApiException(code: 'DELETE_FAILED', message: lastErrorMessage);
  }

  Future<bool> deleteDocument({required int idSal, required String id, int? sanadType, String? password}) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) throw const DocumentApiException(code: 'INVALID_ID', message: 'شناسه سند نامعتبر است.');
    if (sanadType == 12) return deleteSaleDocument(idSal: idSal, id: cleanId, password: password);
    final headers = await _headers(json: true);
    final endpoints = <Uri>[];
    if (sanadType == 113) {
      endpoints.add(Uri.parse('$baseUrl/api/documents/partner-sale/$idSal/${Uri.encodeComponent(cleanId)}'));
      endpoints.add(Uri.parse('$baseUrl/api/documents/partner-sale/${Uri.encodeComponent(cleanId)}'));
    }
    endpoints.add(Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(cleanId)}'));
    endpoints.add(Uri.parse('$baseUrl/api/documents/${Uri.encodeComponent(cleanId)}'));
    endpoints.add(Uri.parse('$baseUrl/api/documents').replace(queryParameters: {'idSal': '$idSal', 'id': cleanId}));
    String lastErrorMessage = 'خطا در ارتباط با سرور هنگام حذف سند.';
    for (final uri in endpoints) {
      try {
        final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
        if (response.statusCode >= 200 && response.statusCode < 300) { invalidateHistory(); return true; }
        if (response.statusCode != 404 && response.statusCode != 405) lastErrorMessage = _extractMessage(response.body, lastErrorMessage);
      } catch (e) { lastErrorMessage = e.toString(); }
    }
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/documents/delete'), headers: headers, body: jsonEncode({'idSal': idSal, 'id': cleanId})).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) { invalidateHistory(); return true; }
    } catch (_) {}
    throw DocumentApiException(code: 'DELETE_FAILED', message: lastErrorMessage);
  }

  Future<bool> setBookmark({
    required int idSal,
    required String id,
    required bool isBookmarked,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(id)}/bookmark'),
      headers: await _headers(json: true),
      body: jsonEncode({'isBookmarked': isBookmarked}),
    ).timeout(const Duration(seconds: 20));

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      body = <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] == false) {
      throw DocumentApiException(
        code: body['code']?.toString() ?? 'BOOKMARK_FAILED',
        message: body['message']?.toString() ?? 'تغییر وضعیت نشان سند ناموفق بود.',
      );
    }

    final data = body['data'];
    return data is Map ? data['isBookmarked'] == true : isBookmarked;
  }

  Future<DocumentModel> getDocument({required int idSal, required String id}) async {
    final response = await http.get(Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(id)}'), headers: await _headers(json: false)).timeout(const Duration(seconds: 15));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در دریافت سند.');
  }

  Future<List<DocumentModel>> getHistory({int idSal = 0, int sanadType = 12, int page = 1, int pageSize = 30, bool forceRefresh = false, bool bookmarkedOnly = false}) async {
    final normalizedSal = idSal <= 0 ? 0 : idSal;
    final key = '$normalizedSal|$sanadType|$page|$pageSize|$bookmarkedOnly';
    if (!forceRefresh) { final cached = _historyCache[key]; if (cached != null) return List<DocumentModel>.from(cached.data); }
    final uri = Uri.parse('$baseUrl/api/documents/history').replace(queryParameters: {'idSal': '$normalizedSal', 'sanadType': '$sanadType', 'page': '$page', 'pageSize': '$pageSize', 'bookmarkedOnly': '$bookmarkedOnly'});
    final result = await _getHistoryFromUri(uri);
    _historyCache[key] = _HistoryCacheEntry(List<DocumentModel>.from(result));
    return result;
  }

  Future<List<DocumentModel>> getPartnerSaleHistory({int idSal = 0, int page = 1, int pageSize = 30, bool forceRefresh = false, bool bookmarkedOnly = false}) async => getHistory(idSal: idSal, sanadType: 113, page: page, pageSize: pageSize, forceRefresh: forceRefresh, bookmarkedOnly: bookmarkedOnly);
  Future<List<DocumentModel>> getPurchaseHistory({int idSal = 0, int page = 1, int pageSize = 30, bool forceRefresh = false, bool bookmarkedOnly = false}) async => getHistory(idSal: idSal, sanadType: 11, page: page, pageSize: pageSize, forceRefresh: forceRefresh, bookmarkedOnly: bookmarkedOnly);

  Future<List<DocumentModel>> _getHistoryFromUri(Uri uri) async {
    late http.Response response;
    try { response = await http.get(uri, headers: await _headers(json: false)).timeout(const Duration(seconds: 15)); }
    on TimeoutException { throw const DocumentApiException(code: 'REQUEST_TIMEOUT', message: 'دریافت تاریخچه بیشتر از ۱۵ ثانیه طول کشید. اتصال API را بررسی کنید.'); }
    on Object catch (e) { throw DocumentApiException(code: 'NETWORK_ERROR', message: 'ارتباط با API برقرار نشد: $e'); }
    Map<String, dynamic> body;
    try { final decoded = jsonDecode(response.body); if (decoded is! Map<String, dynamic>) throw const FormatException(); body = decoded; }
    catch (_) { throw const DocumentApiException(code: 'INVALID_RESPONSE', message: 'پاسخ نامعتبر از سرور دریافت شد.'); }
    final result = DocumentHistoryApiResponse.fromJson(body);
    if (response.statusCode < 200 || response.statusCode >= 300 || !result.success) throw DocumentApiException(code: result.code.isEmpty ? 'HTTP_${response.statusCode}' : result.code, message: result.message.isEmpty ? 'خطا در دریافت تاریخچه اسناد.' : result.message, errors: result.errors, warnings: result.warnings);
    return result.data;
  }

  String _extractCode(String body, String fallback) {
    try { final decoded = jsonDecode(body); if (decoded is Map<String, dynamic>) return decoded['code']?.toString() ?? decoded['errorCode']?.toString() ?? fallback; } catch (_) {}
    return fallback;
  }

  String _extractMessage(String body, String fallback) {
    try { final decoded = jsonDecode(body); if (decoded is Map<String, dynamic>) return decoded['message']?.toString() ?? decoded['msg']?.toString() ?? fallback; } catch (_) {}
    return fallback;
  }

  DocumentModel _parseDocumentResponse(http.Response response, {required String fallbackMessage}) {
    Map<String, dynamic> body;
    try { final decoded = jsonDecode(response.body); if (decoded is! Map<String, dynamic>) throw const FormatException(); body = decoded; }
    catch (_) { throw const DocumentApiException(code: 'INVALID_RESPONSE', message: 'پاسخ نامعتبر از سرور دریافت شد.'); }
    final result = DocumentApiResponse.fromJson(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (result.data != null) return result.data!;
      final fallbackDoc = DocumentModel.fromJson(body);
      if (fallbackDoc.id.isNotEmpty || fallbackDoc.idFaktor > 0) return fallbackDoc;
      if (result.success || body['isSuccess'] == true || body['success'] == true) return DocumentModel(idSal: (body['idSal'] as num?)?.toInt() ?? 1405, id: body['id']?.toString() ?? '1', sanadType: (body['sanadType'] as num?)?.toInt() ?? 113, idAnbar: 1, idTaraf: 0, idTarafType: 1, idFaktor: (body['idFaktor'] as num?)?.toInt() ?? 0, sabtDate: body['sabtDate']?.toString() ?? '', totalAmount: (body['totalAmount'] as num?)?.toDouble() ?? 0, isFinal: true, description: body['description']?.toString(), tarafName: null, items: const []);
    }
    if (response.statusCode == 401) throw const DocumentApiException(code: 'UNAUTHORIZED', message: 'نشست ورود شما معتبر نیست. دوباره وارد شوید.');
    throw DocumentApiException(code: result.code.isEmpty ? 'HTTP_${response.statusCode}' : result.code, message: result.message.isNotEmpty ? result.message : fallbackMessage, errors: result.errors, warnings: result.warnings);
  }
}
