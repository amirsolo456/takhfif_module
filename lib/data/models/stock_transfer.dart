class StockTransferWarehouse {
  final int id;
  final String name;

  const StockTransferWarehouse({required this.id, required this.name});

  factory StockTransferWarehouse.fromJson(Map<String, dynamic> json) {
    return StockTransferWarehouse(
      id: (json['id'] as num?)?.toInt() ?? int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class StockTransferInventory {
  final String idKala;
  final String name;
  final double stock;

  const StockTransferInventory({
    required this.idKala,
    required this.name,
    required this.stock,
  });

  factory StockTransferInventory.fromJson(Map<String, dynamic> json) {
    return StockTransferInventory(
      idKala: json['idKala']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toDouble() ?? double.tryParse('${json['stock']}') ?? 0,
    );
  }
}
