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
  bool _isSmsMockMode = false;
  String _smsTemplateName = '';
  String _smsSender = '';
  List<Map<String, dynamic>> _smsTemplates = [];
  final List<Map<String, dynamic>> _smsLogs = [];
  Map<String, dynamic>? _accountInfo;
  bool _isLoadingAccountInfo = false;

  List<DiscountCode> get codes => _codes;
  List<DiscountUsageHistory> get history => _history;
  bool get isLoading => _isLoading;
  String get smsApiKey => _smsApiKey;
  bool get isSmsMockMode => _isSmsMockMode;
  String get smsTemplateName => _smsTemplateName;
  String get smsSender => _smsSender;
  List<Map<String, dynamic>> get smsTemplates => _smsTemplates;
  List<Map<String, dynamic>> get smsLogs => _smsLogs;
  Map<String, dynamic>? get accountInfo => _accountInfo;
  bool get isLoadingAccountInfo => _isLoadingAccountInfo;

  Future<void> init() async {
    await _service.init();
    final savedApiKey = await _service.getSetting('sms_api_key');
    _smsApiKey = savedApiKey?.trim() ?? '';

    _smsTemplateName =
        await _service.getSetting('sms_template_name') ?? 'templatemobile';

    final savedSender = await _service.getSetting('sms_sender');
    _smsSender = savedSender?.trim() ?? '';

    _smsTemplates = await _service.getSmsTemplates();

    final hasTemplate = _smsTemplates.any(
      (template) => template['name']?.toString() == 'templatemobile',
    );

    if (!hasTemplate) {
      await addSmsTemplate(
        'templatemobile',
        'دامداری آریا دام خاتون\n'
        'سفارش شما با شماره فاکتور : %token\n'
        'با موفقیت ثبت گردید💐🙏🏻\n'
        'شماره تماس پشتیبان:\n'
        '۰۹۱۹۲۴۱۰۲۰۷\n'
        'این کد رو میتونید در خرید بعدیتون استفاده کنید (کد هدیه) : %token3',
      );
      _smsTemplates = await _service.getSmsTemplates();
    }

    final mockModeStr = await _service.getSetting('sms_mock_mode');
    _isSmsMockMode = mockModeStr == 'true';
    await refreshData();

    if (_smsApiKey.isNotEmpty || _isSmsMockMode) {
      await fetchAccountBalance();
    }
    notifyListeners();
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
    fetchAccountBalance();
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
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw Exception('شماره موبایل تست را وارد کنید.');
    }

    final templateName =
        _smsTemplateName.trim().isEmpty ? 'templatemobile' : _smsTemplateName.trim();

    const testToken = '12345';
    const testToken3 = 'TEST-123';

    try {
      final response = await _service.sendTemplateSms(
        phone: normalizedPhone,
        template: templateName,
        token: testToken,
        token3: testToken3,
      );
      _addSmsLog('تست Pattern', response);
      if (!response.success) {
        throw Exception(response.message);
      }
    } catch (e) {
      _addSmsLog('خطای تست Pattern', null, error: e.toString());
      rethrow;
    }
  }


  Future<Map<String, dynamic>> fetchAccountInfo() async {
    final smsService = KavenegarSmsService(
      apiKey: _smsApiKey,
      useMock: _isSmsMockMode,
    );
    return await smsService.getAccountInfo();
  }

  Future<void> fetchAccountBalance() async {
    _isLoadingAccountInfo = true;
    notifyListeners();
    try {
      _accountInfo = await fetchAccountInfo();
    } catch (e) {
      debugPrint('Error fetching account balance: $e');
    } finally {
      _isLoadingAccountInfo = false;
      notifyListeners();
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

  String renderSmsBody(
    String body, {
    required String name,
    required String code,
    String? token2,
    String? token3,
  }) {
    return body
        .replaceAll(RegExp(r'@\S+'), name)
        .replaceAll('%token3', token3 ?? code)
        .replaceAll('%token2', token2 ?? '')
        .replaceAll('%token', code);
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
