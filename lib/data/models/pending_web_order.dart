class PendingWebOrder {
  final int id;
  final int idSal;
  final String orderNumber;
  final int idFaktor;
  final int sanadType;
  final int idAnbar;
  final int? tarafId;
  final int? tarafType;
  final String? tarafName;
  final String? sabtDate;
  final String? firstName;
  final String? lastName;
  final String mobile;
  final String? address;
  final DateTime? createdAt;
  final String? notes;
  final double totalAmount;
  final List<PendingWebOrderItem> items;

  const PendingWebOrder({
    required this.id,
    required this.idSal,
    required this.orderNumber,
    required this.idFaktor,
    required this.sanadType,
    required this.idAnbar,
    required this.tarafId,
    required this.tarafType,
    required this.tarafName,
    required this.sabtDate,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.address,
    required this.createdAt,
    required this.notes,
    required this.totalAmount,
    required this.items,
  });

  factory PendingWebOrder.fromJson(Map<String, dynamic> json) {
    final name = json['tarafName'] as String?;
    return PendingWebOrder(
      id: (json['id'] as num).toInt(),
      idSal: (json['idSal'] as num?)?.toInt() ?? 1405,
      orderNumber: json['orderNumber'] as String? ?? '',
      idFaktor: (json['idFaktor'] as num?)?.toInt() ?? 0,
      sanadType: (json['sanadType'] as num?)?.toInt() ?? 7,
      idAnbar: (json['idAnbar'] as num?)?.toInt() ?? 1,
      tarafId: (json['idTaraf'] as num?)?.toInt(),
      tarafType: (json['idTarafType'] as num?)?.toInt(),
      tarafName: name,
      sabtDate: json['sabtDate'] as String?,
      firstName: name,
      lastName: null,
      mobile: '',
      address: null,
      createdAt: null,
      notes: json['description'] as String?,
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
  final double? purchasePrice;

  const PendingWebOrderItem({
    required this.id,
    required this.kalaId,
    required this.kalaName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.purchasePrice,
  });

  factory PendingWebOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingWebOrderItem(
      id: (json['id'] as num).toInt(),
      kalaId: json['kalaId'] as String? ?? '',
      kalaName: json['kalaName'] as String? ?? json['kalaId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
    );
  }
}
