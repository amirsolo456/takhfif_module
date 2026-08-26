
enum DiscountType { percentage, fixed, freeShipping }

class DiscountCode {
  final int? id;
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime expirationDate;
  final int usageLimit;
  final int usageCount;
  final int remainingUsage;
  final double? minimumPurchaseAmount;
  final double? maximumDiscountAmount;
  final bool isActive;
  final DateTime createdAt;

  DiscountCode({
    this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.expirationDate,
    required this.usageLimit,
    this.usageCount = 0,
    required this.remainingUsage,
    this.minimumPurchaseAmount,
    this.maximumDiscountAmount,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'start_date': startDate.toIso8601String(),
      'expiration_date': expirationDate.toIso8601String(),
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'remaining_usage': remainingUsage,
      'minimum_purchase': minimumPurchaseAmount,
      'maximum_discount': maximumDiscountAmount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DiscountCode.fromMap(Map<String, dynamic> map) {
    return DiscountCode(
      id: map['id'],
      code: map['code'],
      discountType: DiscountType.values.byName(map['discount_type']),
      discountValue: map['discount_value'],
      startDate: DateTime.parse(map['start_date']),
      expirationDate: DateTime.parse(map['expiration_date']),
      usageLimit: map['usage_limit'],
      usageCount: map['usage_count'],
      remainingUsage: map['remaining_usage'],
      minimumPurchaseAmount: map['minimum_purchase'],
      maximumDiscountAmount: map['maximum_discount'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get status {
    if (!isActive) return 'غیرفعال';
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'در انتظار';
    if (now.isAfter(expirationDate)) return 'منقضی شده';
    if (remainingUsage <= 0) return 'تمام شده';
    return 'فعال';
  }

  DiscountCode copyWith({
    int? id,
    String? code,
    DiscountType? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? expirationDate,
    int? usageLimit,
    int? usageCount,
    int? remainingUsage,
    double? minimumPurchaseAmount,
    double? maximumDiscountAmount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DiscountCode(
      id: id ?? this.id,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      expirationDate: expirationDate ?? this.expirationDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      remainingUsage: remainingUsage ?? this.remainingUsage,
      minimumPurchaseAmount: minimumPurchaseAmount ?? this.minimumPurchaseAmount,
      maximumDiscountAmount: maximumDiscountAmount ?? this.maximumDiscountAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
