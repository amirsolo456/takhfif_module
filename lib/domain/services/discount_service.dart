import '../../data/models/discount_code.dart';
import '../../data/models/discount_usage_history.dart';
import '../../data/repositories/discount_repository.dart';
import '../../core/utils/discount_code_generator.dart';

class DiscountService {
  final DiscountRepository _repository = DiscountRepository();

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
    String? phone,
    String? product,
    required double amount,
    String? description,
  }) async {
    await _repository.consumeDiscountCode(
      code: code.toUpperCase(),
      customerPhone: phone,
      purchasedProduct: product,
      purchaseAmount: amount,
      description: description,
    );
  }

  Future<void> toggleStatus(DiscountCode code) async {
    final updated = code.copyWith(isActive: !code.isActive);
    await _repository.updateDiscountCode(updated);
  }

  Future<void> clearAll() => _repository.clearAll();

  Future<void> insertCode(DiscountCode code) => _repository.insertDiscountCode(code);
  Future<void> insertHistory(DiscountUsageHistory history) => _repository.insertUsageHistory(history);
}
