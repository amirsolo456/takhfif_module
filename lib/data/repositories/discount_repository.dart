import '../../infrastructure/database/local_database.dart';
import '../../infrastructure/database/database_factory.dart';
import '../models/discount_code.dart';
import '../models/discount_usage_history.dart';

class DiscountRepository {
  final LocalDatabase _db = DatabaseFactory.instance;

  Future<void> init() async {
    await _db.initialize();
  }

  Future<int> insertDiscountCode(DiscountCode discountCode) async {
    return await _db.insert('discount_codes', discountCode.toMap());
  }

  Future<List<DiscountCode>> getAllDiscountCodes() async {
    final List<Map<String, dynamic>> maps = await _db.query('discount_codes', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => DiscountCode.fromMap(maps[i]));
  }

  Future<DiscountCode?> getDiscountCodeByCode(String code) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'discount_codes',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (maps.isEmpty) return null;
    return DiscountCode.fromMap(maps.first);
  }

  Future<int> updateDiscountCode(DiscountCode discountCode) async {
    return await _db.update(
      'discount_codes',
      discountCode.toMap(),
      where: 'id = ?',
      whereArgs: [discountCode.id],
    );
  }

  Future<bool> consumeDiscountCode({
    required String code,
    String? customerName,
    String? customerPhone,
    String? purchasedProduct,
    required double purchaseAmount,
    String? description,
  }) async {
    await _db.transaction((txn) async {
      final List<Map<String, dynamic>> codes = await txn.query(
        'discount_codes',
        where: 'code = ?',
        whereArgs: [code],
      );

      if (codes.isEmpty) throw Exception('کد تخفیف پیدا نشد.');

      final discount = DiscountCode.fromMap(codes.first);
      final now = DateTime.now();

      if (!discount.isActive) throw Exception('کد تخفیف غیرفعال است.');
      if (now.isBefore(discount.startDate)) throw Exception('تاریخ شروع اعتبار هنوز نرسیده است.');
      if (now.isAfter(discount.expirationDate)) throw Exception('کد تخفیف منقضی شده است.');
      if (discount.remainingUsage <= 0) throw Exception('ظرفیت مصرف تمام شده است.');
      if (discount.minimumPurchaseAmount != null && purchaseAmount < discount.minimumPurchaseAmount!) {
        throw Exception('مبلغ خرید کمتر از کف خرید است.');
      }

      double discountAmount = 0;
      if (discount.discountType == DiscountType.percentage) {
        discountAmount = purchaseAmount * (discount.discountValue / 100);
        if (discount.maximumDiscountAmount != null && discountAmount > discount.maximumDiscountAmount!) {
          discountAmount = discount.maximumDiscountAmount!;
        }
      } else {
        discountAmount = discount.discountValue;
      }

      if (discountAmount > purchaseAmount) {
        discountAmount = purchaseAmount;
      }

      final newRemaining = discount.remainingUsage - 1;
      final newUsageCount = discount.usageCount + 1;
      final newIsActive = newRemaining > 0;

      await txn.update(
        'discount_codes',
        {
          'remaining_usage': newRemaining,
          'usage_count': newUsageCount,
          'is_active': newIsActive ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [discount.id],
      );

      final history = DiscountUsageHistory(
        discountCodeId: discount.id!,
        discountCode: discount.code,
        customerName: customerName,
        customerPhone: customerPhone,
        purchasedProduct: purchasedProduct,
        purchaseAmount: purchaseAmount,
        discountAmount: discountAmount,
        usedAt: now,
        description: description,
      );

      await txn.insert('discount_usage_history', history.toMap());
    });
    return true;
  }

  Future<List<DiscountUsageHistory>> getUsageHistory({String? query}) async {
    String? where;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty) {
      where = 'discount_code LIKE ? OR customer_phone LIKE ? OR purchased_product LIKE ?';
      whereArgs = ['%$query%', '%$query%', '%$query%'];
    }

    final List<Map<String, dynamic>> maps = await _db.query(
      'discount_usage_history',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'used_at DESC',
    );
    return List.generate(maps.length, (i) => DiscountUsageHistory.fromMap(maps[i]));
  }

  Future<void> insertUsageHistory(DiscountUsageHistory history) async {
    await _db.insert('discount_usage_history', history.toMap());
  }

  Future<void> clearAll() async {
    await _db.delete('discount_usage_history');
    await _db.delete('discount_codes');
  }

  Future<String?> getSetting(String key) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> saveSetting(String key, String value) async {
    final existing = await getSetting(key);
    if (existing == null) {
      await _db.insert('app_settings', {'key': key, 'value': value});
    } else {
      await _db.update(
        'app_settings',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  // SMS Templates CRUD
  Future<List<Map<String, dynamic>>> getSmsTemplates() async {
    return await _db.query('sms_templates', orderBy: 'id DESC');
  }

  Future<int> insertSmsTemplate(Map<String, dynamic> template) async {
    return await _db.insert('sms_templates', template);
  }

  Future<int> updateSmsTemplate(int id, Map<String, dynamic> template) async {
    return await _db.update(
      'sms_templates',
      template,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSmsTemplate(int id) async {
    return await _db.delete('sms_templates', where: 'id = ?', whereArgs: [id]);
  }
}
