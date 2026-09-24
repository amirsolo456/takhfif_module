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

class StockTransferHistoryItem {
  final String idKala;
  final String name;
  final double quantity;

  const StockTransferHistoryItem({
    required this.idKala,
    required this.name,
    required this.quantity,
  });

  factory StockTransferHistoryItem.fromJson(Map<String, dynamic> json) {
    return StockTransferHistoryItem(
      idKala: json['idKala']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ??
          double.tryParse('${json['quantity']}') ??
          0,
    );
  }
}

class StockTransferHistory {
  final int idSal;
  final String id;
  final int idFaktor;
  final String sabtDate;
  final String? note;
  final int sourceAnbarId;
  final String sourceAnbarName;
  final int destinationAnbarId;
  final String destinationAnbarName;
  final int itemCount;
  final List<StockTransferHistoryItem> items;

  const StockTransferHistory({
    required this.idSal,
    required this.id,
    required this.idFaktor,
    required this.sabtDate,
    required this.note,
    required this.sourceAnbarId,
    required this.sourceAnbarName,
    required this.destinationAnbarId,
    required this.destinationAnbarName,
    required this.itemCount,
    required this.items,
  });

  factory StockTransferHistory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return StockTransferHistory(
      idSal: (json['idSal'] as num?)?.toInt() ?? 0,
      id: json['id']?.toString() ?? '',
      idFaktor: (json['idFaktor'] as num?)?.toInt() ?? 0,
      sabtDate: json['sabtDate']?.toString() ?? '',
      note: json['note']?.toString(),
      sourceAnbarId: (json['sourceAnbarId'] as num?)?.toInt() ?? 0,
      sourceAnbarName: json['sourceAnbarName']?.toString() ?? '—',
      destinationAnbarId: (json['destinationAnbarId'] as num?)?.toInt() ?? 0,
      destinationAnbarName: json['destinationAnbarName']?.toString() ?? '—',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((x) => StockTransferHistoryItem.fromJson(
                    Map<String, dynamic>.from(x),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

class StockTransferProductWarehouseInventory {
  final int idAnbar;
  final String anbarName;
  final double stock;

  const StockTransferProductWarehouseInventory({
    required this.idAnbar,
    required this.anbarName,
    required this.stock,
  });

  factory StockTransferProductWarehouseInventory.fromJson(
      Map<String, dynamic> json) {
    return StockTransferProductWarehouseInventory(
      idAnbar: (json['idAnbar'] as num?)?.toInt() ??
          int.tryParse('${json['idAnbar']}') ??
          0,
      anbarName: json['anbarName']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toDouble() ??
          double.tryParse('${json['stock']}') ??
          0,
    );
  }
}