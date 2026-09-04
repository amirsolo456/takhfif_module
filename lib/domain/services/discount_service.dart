import '../../data/models/discount_code.dart';
import '../../data/models/discount_usage_history.dart';
import '../../data/repositories/discount_repository.dart';
import '../../core/utils/discount_code_generator.dart';
import '../../infrastructure/external_services/sms_service.dart';

class DiscountService {
  final DiscountRepository _repository = DiscountRepository();

  Future<void> init() => _repository.init();

  Future<List<DiscountCode>> getAllCodes() => _repository.getAllDiscountCodes();

  Future<List<DiscountUsageHistory>> getHistory({String? query}) => 
      _repository.getUsageHistory(query: query);

  Future<String> createDiscount({
    required DiscountType type,
    required double value,
    required DateTime start,
    required DateTime end,
    required int limit,
    double? minPurchase,
    double? maxDiscount,
  }) async {
    String newCode;
    while (true) {
      newCode = DiscountCodeGenerator.generate();
      final existing = await _repository.getDiscountCodeByCode(newCode);
      if (existing == null) break;
    }

    final discount = DiscountCode(
      code: newCode,
      discountType: type,
      discountValue: value,
      startDate: start,
      expirationDate: end,
      usageLimit: limit,
      remainingUsage: limit,
      minimumPurchaseAmount: minPurchase,
      maximumDiscountAmount: maxDiscount,
      createdAt: DateTime.now(),
    );

    await _repository.insertDiscountCode(discount);
    return newCode;
  }

  Future<void> consumeCode({
    required String code,
    String? customerName,
    String? phone,
    String? product,
    required double amount,
    String? description,
  }) async {
    await _repository.consumeDiscountCode(
      code: code.toUpperCase(),
      customerName: customerName,
      customerPhone: phone,
      purchasedProduct: product,
      purchaseAmount: amount,
      description: description,
    );
  }

  Future<SmsResponse> sendCustomSms({
    required String phone,
    required String message,
  }) async {
    final apiKey = await _repository.getSetting('sms_api_key');
    final mockModeStr = await _repository.getSetting('sms_mock_mode');
    final sender = await _repository.getSetting('sms_sender');
    final isMock = mockModeStr == 'true';

    final smsService = KavenegarSmsService(
      apiKey: apiKey ?? KavenegarSmsService.defaultApiKey,
      useMock: isMock,
    );

    return await smsService.sendDirectSms(phone: phone, message: message, sender: sender);
  }

  Future<void> toggleStatus(DiscountCode code) async {
    final updated = code.copyWith(isActive: !code.isActive);
    await _repository.updateDiscountCode(updated);
  }

  Future<void> clearAll() => _repository.clearAll();

  Future<String?> getSetting(String key) => _repository.getSetting(key);
  Future<void> saveSetting(String key, String value) => _repository.saveSetting(key, value);

  Future<List<Map<String, dynamic>>> getSmsTemplates() => _repository.getSmsTemplates();
  Future<void> addSmsTemplate(String name, String body) => 
      _repository.insertSmsTemplate({'name': name, 'body': body});
  Future<void> updateSmsTemplate(int id, String name, String body) => 
      _repository.updateSmsTemplate(id, {'name': name, 'body': body});
  Future<void> deleteSmsTemplate(int id) => _repository.deleteSmsTemplate(id);

  Future<void> insertCode(DiscountCode code) => _repository.insertDiscountCode(code);
  Future<void> insertHistory(DiscountUsageHistory history) => _repository.insertUsageHistory(history);
}
