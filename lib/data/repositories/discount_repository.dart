import '../database/database_helper.dart';
import '../models/discount_code.dart';
import '../models/discount_usage_history.dart';

class DiscountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertDiscountCode(DiscountCode discountCode) async {
    final db = await _dbHelper.database;
    return await db.insert('discount_codes', discountCode.toMap());
  }

  Future<List<DiscountCode>> getAllDiscountCodes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('discount_codes', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => DiscountCode.fromMap(maps[i]));
  }

  Future<DiscountCode?> getDiscountCodeByCode(String code) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'discount_codes',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (maps.isEmpty) return null;
    return DiscountCode.fromMap(maps.first);
  }

  Future<int> updateDiscountCode(DiscountCode discountCode) async {
    final db = await _dbHelper.database;
    return await db.update(
      'discount_codes',
      discountCode.toMap(),
      where: 'id = ?',
      whereArgs: [discountCode.id],
    );
  }

  Future<bool> consumeDiscountCode({
    required String code,
    String? customerPhone,
    String? purchasedProduct,
    required double purchaseAmount,
    String? description,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction<bool>((txn) async {
      // 1. Find the code
      final List<Map<String, dynamic>> codes = await txn.query(
        'discount_codes',
        where: 'code = ?',
        whereArgs: [code],
      );

      if (codes.isEmpty) throw Exception('کد تخفیف پیدا نشد.');

      final discount = DiscountCode.fromMap(codes.first);
      final now = DateTime.now();

      // 2. Validation
      if (!discount.isActive) throw Exception('کد تخفیف غیرفعال است.');
      if (now.isBefore(discount.startDate)) throw Exception('تاریخ شروع اعتبار کد تخفیف هنوز نرسیده است.');
      if (now.isAfter(discount.expirationDate)) throw Exception('کد تخفیف منقضی شده است.');
      if (discount.remainingUsage <= 0) throw Exception('ظرفیت مصرف این کد تمام شده است.');
      if (discount.minimumPurchaseAmount != null && purchaseAmount < discount.minimumPurchaseAmount!) {
        throw Exception('مبلغ خرید کمتر از حداقل مبلغ مجاز برای این کد است.');
      }

      // 3. Calculate discount amount
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

      // 4. Update Discount Code
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

      // 5. Insert History
      final history = DiscountUsageHistory(
        discountCodeId: discount.id!,
        discountCode: discount.code,
        customerPhone: customerPhone,
        purchasedProduct: purchasedProduct,
        purchaseAmount: purchaseAmount,
        discountAmount: discountAmount,
        usedAt: now,
        description: description,
      );

      await txn.insert('discount_usage_history', history.toMap());

      return true;
    });
  }

  Future<List<DiscountUsageHistory>> getUsageHistory({String? query}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty) {
      where = 'discount_code LIKE ? OR customer_phone LIKE ? OR purchased_product LIKE ?';
      whereArgs = ['%$query%', '%$query%', '%$query%'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'discount_usage_history',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'used_at DESC',
    );
    return List.generate(maps.length, (i) => DiscountUsageHistory.fromMap(maps[i]));
  }

  Future<void> insertUsageHistory(DiscountUsageHistory history) async {
    final db = await _dbHelper.database;
    await db.insert('discount_usage_history', history.toMap());
  }

  Future<void> clearAll() async {
    await _dbHelper.clearAllData();
  }
}
