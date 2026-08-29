class OrderItemModel {
  final String kalaId;
  final String kalaName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemModel({
    required this.kalaId,
    required this.kalaName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      kalaId: json['kalaId'] ?? '',
      kalaName: json['kalaName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kalaId': kalaId,
      'kalaName': kalaName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}
