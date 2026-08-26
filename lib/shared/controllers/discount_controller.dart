import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/discount_code.dart';
import '../../data/models/discount_usage_history.dart';
import '../../domain/services/discount_service.dart';
import '../../infrastructure/external_services/sms_service.dart';

class DiscountController extends ChangeNotifier {
  final DiscountService _service = DiscountService();

  List<DiscountCode> _codes = [];
  List<DiscountUsageHistory> _history = [];
  bool _isLoading = false;
  String _smsApiKey = '';
  bool _isSmsMockMode = true;
  String _smsTemplateName = '';
  String _smsSender = '';
  List<Map<String, dynamic>> _smsTemplates = [];
  final List<Map<String, dynamic>> _smsLogs = [];

  List<DiscountCode> get codes => _codes;
  List<DiscountUsageHistory> get history => _history;
  bool get isLoading => _isLoading;
  String get smsApiKey => _smsApiKey;
  bool get isSmsMockMode => _isSmsMockMode;
  String get smsTemplateName => _smsTemplateName;
  String get smsSender => _smsSender;
  List<Map<String, dynamic>> get smsTemplates => _smsTemplates;
  List<Map<String, dynamic>> get smsLogs => _smsLogs;

  Future<void> init() async {
    await _service.init();
    _smsApiKey = await _service.getSetting('sms_api_key') ?? '';
    _smsTemplateName = await _service.getSetting('sms_template_name') ?? '';
    
    final savedSender = await _service.getSetting('sms_sender');
    _smsSender = (savedSender == null || savedSender.isEmpty) ? '2000660110' : savedSender;
    
    _smsTemplates = await _service.getSmsTemplates();

    // If no templates exist, add a professional default one
    if (_smsTemplates.isEmpty) {
      await addSmsTemplate(
        'پیام آزمایشی سیستمی',
        'این یک پیام آزمایشی برای بررسی صحت عملکرد سیستم ارسال پیام است\nلغو11',
      );
    }

    final mockModeStr = await _service.getSetting('sms_mock_mode');
    _isSmsMockMode = mockModeStr == 'true' || mockModeStr == null;
    await refreshData();
  }

  Future<void> updateSmsSettings(String apiKey, bool isMock, {String? templateName, String? sender}) async {
    _smsApiKey = apiKey.trim();
    _isSmsMockMode = isMock;
    if (templateName != null) _smsTemplateName = templateName.trim();
    if (sender != null) _smsSender = sender.trim();

    await _service.saveSetting('sms_api_key', _smsApiKey);
    await _service.saveSetting('sms_mock_mode', isMock.toString());
    if (templateName != null) {
      await _service.saveSetting('sms_template_name', _smsTemplateName);
    }
    if (sender != null) {
      await _service.saveSetting('sms_sender', _smsSender);
    }
    notifyListeners();
    debugPrint('SMS Settings Updated: Mock=$_isSmsMockMode, KeyLength=${_smsApiKey.length}, Sender=$_smsSender');
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    _codes = await _service.getAllCodes();
    _history = await _service.getHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> createDiscount({
    required DiscountType type,
    required double value,
    required DateTime start,
    required DateTime end,
    required int limit,
    double? minPurchase,
    double? maxDiscount,
  }) async {
    final code = await _service.createDiscount(
      type: type,
      value: value,
      start: start,
      end: end,
      limit: limit,
      minPurchase: minPurchase,
      maxDiscount: maxDiscount,
    );
    await refreshData();
    return code;
  }

  Future<void> consumeCode({
    required String code,
    String? customerName,
    String? phone,
    String? product,
    required double amount,
    String? description,
  }) async {
    try {
      await _service.consumeCode(
        code: code,
        customerName: customerName,
        phone: phone,
        product: product,
        amount: amount,
        description: description,
      );
      await refreshData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleCodeStatus(DiscountCode code) async {
    await _service.toggleStatus(code);
    await refreshData();
  }

  Future<void> searchHistory(String query) async {
    _history = await _service.getHistory(query: query);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    await refreshData();
  }

  Future<String?> exportData() async {
    final data = {
      'codes': _codes.map((e) => e.toMap()).toList(),
      'history': _history.map((e) => e.toMap()).toList(),
    };

    final jsonString = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'discount_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);
    return file.path;
  }

  Future<bool> importData() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        await _service.clearAll();

        final List codesMap = data['codes'] ?? [];
        final List historyMap = data['history'] ?? [];

        for (var map in codesMap) {
          await _service.insertCode(DiscountCode.fromMap(map));
        }

        for (var map in historyMap) {
          await _service.insertHistory(DiscountUsageHistory.fromMap(map));
        }

        await refreshData();
        return true;
      }
    } catch (e) {
      debugPrint('Import error: $e');
    }
    return false;
  }

  Future<void> addSmsTemplate(String name, String body) async {
    await _service.addSmsTemplate(name, body);
    _smsTemplates = await _service.getSmsTemplates();
    notifyListeners();
  }

  Future<void> updateSmsTemplate(int id, String name, String body) async {
    await _service.updateSmsTemplate(id, name, body);
    _smsTemplates = await _service.getSmsTemplates();
    notifyListeners();
  }

  Future<void> deleteSmsTemplate(int id) async {
    await _service.deleteSmsTemplate(id);
    _smsTemplates = await _service.getSmsTemplates();
    notifyListeners();
  }

  Future<void> testSmsConnection(String phone) async {
    final dynamicSmsService = KavenegarSmsService(
      apiKey: _smsApiKey,
      useMock: _isSmsMockMode,
    );

    // Find the body of the active template
    String body = 'این یک پیامک تست است. کد: %token';
    final activeTemplate = _smsTemplates.firstWhere(
      (t) => t['name'] == _smsTemplateName,
      orElse: () => {'body': body},
    );

    final renderedMessage = renderSmsBody(
      activeTemplate['body'] ?? body,
      name: 'مشتری تست',
      code: 'TEST-123',
    );

    try {
      // ALWAYS use sendDirectSms for app-defined templates to allow full text control
      final response = await dynamicSmsService.sendDirectSms(
        phone: phone,
        message: renderedMessage,
        sender: _smsSender,
      );
      _addSmsLog('تست اتصال', response);
    } catch (e) {
      _addSmsLog('خطای تست', null, error: e.toString());
      rethrow;
    }
  }

  void _addSmsLog(String type, SmsResponse? response, {String? error}) {
    _smsLogs.insert(0, {
      'time': DateTime.now(),
      'type': type,
      'status': response?.statusCode ?? 'Error',
      'message': response?.message ?? error,
      'raw': response?.rawBody ?? error,
      'success': response?.success ?? false,
      'cost': response?.cost,
      'messageId': response?.messageId,
      'receptor': response?.receptor,
      'statusText': response?.statusText,
    });
    if (_smsLogs.length > 20) _smsLogs.removeLast();
    notifyListeners();
  }

  String renderSmsBody(String body, {required String name, required String code}) {
    String rendered = body;
    // Replace @name, @customer, etc. with actual name
    rendered = rendered.replaceAll(RegExp(r'@\S+'), name);
    // Replace %token with code
    rendered = rendered.replaceAll('%token', code);
    return rendered;
  }

  Future<void> sendDirectSms(String phone, String message) async {
    try {
      final response = await _service.sendCustomSms(phone: phone, message: message);
      _addSmsLog('ارسال دستی', response);
    } catch (e) {
      _addSmsLog('خطای ارسال', null, error: e.toString());
      rethrow;
    }
  }
}
