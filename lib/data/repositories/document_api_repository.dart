import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

class DocumentApiRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  DocumentApiRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;

  Future<Map<String, String>> _headers({required bool json}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    if (userId != null && userId > 0) headers['X-User-Id'] = '$userId';
    return headers;
  }

  Future<DocumentModel> createDocument(CreateDocumentRequest request) async {
    final response = await http.post(Uri.parse('$baseUrl/api/documents'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 20));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت سند.');
  }

  Future<DocumentModel> createPurchaseDocument({required CreateDocumentRequest request}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/documents/purchase'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 30));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت سند خرید.');
  }

  Future<DocumentModel> createPartnerSaleDocument({required CreateDocumentRequest request}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/documents/partner-sale'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 30));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در ثبت فروش از انبار همکار.');
  }

  Future<DocumentModel> updatePartnerSaleDocument({required int idSal, required String id, required CreateDocumentRequest request}) async {
    final response = await http.put(Uri.parse('$baseUrl/api/documents/partner-sale/$idSal/${Uri.encodeComponent(id)}'), headers: await _headers(json: true), body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 30));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در ویرایش فروش از انبار همکار.');
  }

  Future<DocumentModel> deletePartnerSaleDocument({required int idSal, required String id}) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/documents/partner-sale/$idSal/${Uri.encodeComponent(id)}'), headers: await _headers(json: false)).timeout(const Duration(seconds: 30));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در حذف فروش از انبار همکار.');
  }

  Future<DocumentModel> getDocument({required int idSal, required String id}) async {
    final response = await http.get(Uri.parse('$baseUrl/api/documents/$idSal/${Uri.encodeComponent(id)}'), headers: await _headers(json: false)).timeout(const Duration(seconds: 15));
    return _parseDocumentResponse(response, fallbackMessage: 'خطا در دریافت سند.');
  }

  Future<List<DocumentModel>> getHistory({int idSal = 0, int sanadType = 12, int page = 1, int pageSize = 30}) async {
    final uri = Uri.parse('$baseUrl/api/documents/history').replace(queryParameters: {'idSal': '${idSal < 0 ? 0 : idSal}', 'sanadType': '$sanadType', 'page': '$page', 'pageSize': '$pageSize'});
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

  DocumentModel _parseDocumentResponse(http.Response response, {required String fallbackMessage}) {
    Map<String, dynamic> body;
    try { final decoded = jsonDecode(response.body); if (decoded is! Map<String, dynamic>) throw const FormatException(); body = decoded; }
    catch (_) { throw const DocumentApiException(code: 'INVALID_RESPONSE', message: 'پاسخ نامعتبر از سرور دریافت شد.'); }
    final result = DocumentApiResponse.fromJson(body);
    if (response.statusCode < 200 || response.statusCode >= 300 || !result.success || result.data == null) throw DocumentApiException(code: result.code.isEmpty ? 'HTTP_${response.statusCode}' : result.code, message: result.message.isEmpty ? fallbackMessage : result.message, errors: result.errors, warnings: result.warnings);
    return result.data!;
  }
}
