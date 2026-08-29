class Kala {
  final int id;
  final String code;
  final String name;
  final int? typeId;
  final int? unitId;
  final String? barcode;
  final bool isActive;
  final double? purchasePrice;
  final double? salePrice;
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
    this.description,
  });

  factory Kala.fromJson(Map<String, dynamic> json) {
    return Kala(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      typeId: json['typeId'],
      unitId: json['unitId'],
      barcode: json['barcode'],
      isActive: json['isActive'] ?? true,
      purchasePrice: json['purchasePrice'] != null ? (json['purchasePrice'] as num).toDouble() : null,
      salePrice: json['salePrice'] != null ? (json['salePrice'] as num).toDouble() : null,
      description: json['description'],
    );
  }
}
