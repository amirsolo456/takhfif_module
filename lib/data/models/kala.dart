class Kala {
  final String id;
  final String code;
  final String name;
  final int? typeId;
  final int? unitId;
  final String? barcode;
  final bool isActive;
  final double? purchasePrice;
  final double? salePrice;
  final double? stock;
  final String? description;

  Kala({
    required this.id,
    required this.code,
    required this.name,
    this.typeId,
    this.unitId,
    this.barcode,
    this.isActive = true,
    this.purchasePrice,
    this.salePrice,
    this.stock,
    this.description,
  });

  factory Kala.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['code'] ?? '').toString();
    final name = (json['name'] ?? json['kalaName'] ?? '').toString();
    final sale = json['salePrice'] ?? json['mabFrosh'];
    final purchase = json['purchasePrice'] ?? json['mabKharid'];

    return Kala(
      id: id,
      code: (json['code'] ?? json['id'] ?? '').toString(),
      name: name,
      typeId: json['typeId'] ?? json['kalaType'],
      unitId: json['unitId'] ?? json['idSanjesh'],
      barcode: json['barcode'],
      isActive: !(json['isDisabled'] ?? false),
      purchasePrice: purchase is num ? purchase.toDouble() : null,
      salePrice: sale is num ? sale.toDouble() : null,
      stock: json['stock'] is num
          ? (json['stock'] as num).toDouble()
          : json['quantity'] is num
              ? (json['quantity'] as num).toDouble()
              : null,
      description: json['description'],
    );
  }
}
