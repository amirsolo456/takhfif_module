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

  const PendingWebOrder({required this.id, required this.idSal, required this.orderNumber, required this.idFaktor, required this.sanadType, required this.idAnbar, required this.tarafId, required this.tarafType, required this.tarafName, required this.sabtDate, required this.firstName, required this.lastName, required this.mobile, required this.address, required this.createdAt, required this.notes, required this.totalAmount, required this.items});

  factory PendingWebOrder.fromJson(Map<String, dynamic> json) {
    final name = json['tarafName'] as String?;
    return PendingWebOrder(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      idSal: int.tryParse(json['idSal']?.toString() ?? '') ?? 1405,
      orderNumber: json['orderNumber'] as String? ?? '',
      idFaktor: int.tryParse(json['idFaktor']?.toString() ?? '') ?? 0,
      sanadType: int.tryParse(json['sanadType']?.toString() ?? '') ?? 51,
      idAnbar: int.tryParse(json['idAnbar']?.toString() ?? '') ?? 1,
      tarafId: int.tryParse(json['idTaraf']?.toString() ?? ''),
      tarafType: int.tryParse(json['idTarafType']?.toString() ?? ''),
      tarafName: name,
      sabtDate: json['sabtDate']?.toString(),
      firstName: name,
      lastName: null,
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString(),
      createdAt: null,
      notes: json['notes']?.toString() ?? json['description']?.toString(),
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((x) => PendingWebOrderItem.fromJson(Map<String, dynamic>.from(x)))
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

  const PendingWebOrderItem({required this.id, required this.kalaId, required this.kalaName, required this.quantity, required this.unitPrice, required this.totalPrice, required this.purchasePrice});

  factory PendingWebOrderItem.fromJson(Map<String, dynamic> json) {
    // Backend historically returned idKala while some clients used kalaId.
    // Accept both so pending invoices never lose their product identifier.
    final kalaId = (json['kalaId'] ?? json['idKala'])?.toString() ?? '';
    final kalaName = (json['kalaName'] ?? json['idKala'] ?? json['kalaId'])?.toString() ?? '';
    return PendingWebOrderItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      kalaId: kalaId,
      kalaName: kalaName,
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0,
      totalPrice: double.tryParse(json['totalPrice']?.toString() ?? '') ?? 0,
      purchasePrice: json['purchasePrice'] == null ? null : double.tryParse(json['purchasePrice'].toString()),
    );
  }
}
