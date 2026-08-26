class DiscountUsageHistory {
  final int? id;
  final int discountCodeId;
  final String discountCode;
  final String? customerName;
  final String? customerPhone;
  final String? purchasedProduct;
  final double? purchaseAmount;
  final double? discountAmount;
  final DateTime usedAt;
  final String? description;

  DiscountUsageHistory({
    this.id,
    required this.discountCodeId,
    required this.discountCode,
    this.customerName,
    this.customerPhone,
    this.purchasedProduct,
    this.purchaseAmount,
    this.discountAmount,
    required this.usedAt,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'discount_code_id': discountCodeId,
      'discount_code': discountCode,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'purchased_product': purchasedProduct,
      'purchase_amount': purchaseAmount,
      'discount_amount': discountAmount,
      'used_at': usedAt.toIso8601String(),
      'description': description,
    };
  }

  factory DiscountUsageHistory.fromMap(Map<String, dynamic> map) {
    return DiscountUsageHistory(
      id: map['id'],
      discountCodeId: map['discount_code_id'],
      discountCode: map['discount_code'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      purchasedProduct: map['purchased_product'],
      purchaseAmount: map['purchase_amount'],
      discountAmount: map['discount_amount'],
      usedAt: DateTime.parse(map['used_at']),
      description: map['description'],
    );
  }
}
