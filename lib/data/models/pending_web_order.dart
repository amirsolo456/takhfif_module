class PendingWebOrder {
  final int id;
  final String orderNumber;
  final String? firstName;
  final String? lastName;
  final String mobile;
  final String? address;
  final int? tarafId;
  final int? tarafType;
  final DateTime? createdAt;
  final String? notes;
  final double totalAmount;
  final List<PendingWebOrderItem> items;

  const PendingWebOrder({
    required this.id,
    required this.orderNumber,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.address,
    required this.tarafId,
    required this.tarafType,
    required this.createdAt,
    required this.notes,
    required this.totalAmount,
    required this.items,
  });

  factory PendingWebOrder.fromJson(Map<String, dynamic> json) {
    return PendingWebOrder(
      id: (json['id'] as num).toInt(),
      orderNumber: json['orderNumber'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      mobile: json['mobile'] as String? ?? '',
      address: json['address'] as String?,
      tarafId: (json['tarafId'] as num?)?.toInt(),
      tarafType: (json['tarafType'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      notes: json['notes'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map((x) => PendingWebOrderItem.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList(),
    );
  }
}

class PendingWebOrderItem {
  final int id;
  final String kalaId;
  final String kalaName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const PendingWebOrderItem({
    required this.id,
    required this.kalaId,
    required this.kalaName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PendingWebOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingWebOrderItem(
      id: (json['id'] as num).toInt(),
      kalaId: json['kalaId'] as String? ?? '',
      kalaName: json['kalaName'] as String? ?? json['kalaId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
