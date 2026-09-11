class ProfitReportItem {
  final String idKala;
  final double quantity;
  final double salesAmount;
  final double purchaseCost;
  final double profit;

  const ProfitReportItem({required this.idKala, required this.quantity, required this.salesAmount, required this.purchaseCost, required this.profit});

  factory ProfitReportItem.fromJson(Map<String, dynamic> json) => ProfitReportItem(
    idKala: json['idKala'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    salesAmount: (json['salesAmount'] as num?)?.toDouble() ?? 0,
    purchaseCost: (json['purchaseCost'] as num?)?.toDouble() ?? 0,
    profit: (json['profit'] as num?)?.toDouble() ?? 0,
  );
}

class ProfitReport {
  final String fromDate;
  final String toDate;
  final double totalSales;
  final double totalPurchaseCost;
  final double totalProfit;
  final List<ProfitReportItem> items;

  const ProfitReport({required this.fromDate, required this.toDate, required this.totalSales, required this.totalPurchaseCost, required this.totalProfit, required this.items});

  factory ProfitReport.fromJson(Map<String, dynamic> json) => ProfitReport(
    fromDate: json['fromDate'] as String? ?? '',
    toDate: json['toDate'] as String? ?? '',
    totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
    totalPurchaseCost: (json['totalPurchaseCost'] as num?)?.toDouble() ?? 0,
    totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0,
    items: (json['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(ProfitReportItem.fromJson).toList(growable: false),
  );
}
