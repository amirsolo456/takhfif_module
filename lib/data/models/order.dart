import 'dart:convert';

class OrderItem {
  final String productName;
  final int quantity;
  final double buyingPrice;
  final double sellingPrice;

  OrderItem({
    required this.productName, 
    required this.quantity,
    this.buyingPrice = 0,
    this.sellingPrice = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productName: map['product_name'],
      quantity: map['quantity'],
      buyingPrice: (map['buying_price'] ?? 0).toDouble(),
      sellingPrice: (map['selling_price'] ?? 0).toDouble(),
    );
  }
}

class PaymentEntry {
  final double amount;
  final DateTime date;

  PaymentEntry({required this.amount, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory PaymentEntry.fromMap(Map<String, dynamic> map) {
    return PaymentEntry(
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }
}

class Order {
  final int? id;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String? postalCode;
  final String? warehouseCode;
  final String? registrarCode;
  final List<OrderItem> items;
  final List<PaymentEntry> payments;
  final DateTime createdAt;

  Order({
    this.id,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    this.postalCode,
    this.warehouseCode,
    this.registrarCode,
    required this.items,
    required this.payments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'postal_code': postalCode,
      'warehouse_code': warehouseCode,
      'registrar_code': registrarCode,
      'items_json': jsonEncode(items.map((x) => x.toMap()).toList()),
      'payments_json': jsonEncode(payments.map((x) => x.toMap()).toList()),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decodedItems = jsonDecode(map['items_json'] ?? '[]');
    final List<dynamic> decodedPayments = jsonDecode(map['payments_json'] ?? '[]');
    
    return Order(
      id: map['id'],
      customerName: map['customer_name'],
      customerAddress: map['customer_address'],
      customerPhone: map['customer_phone'],
      postalCode: map['postal_code'],
      warehouseCode: map['warehouse_code'],
      registrarCode: map['registrar_code'],
      items: decodedItems.map((x) => OrderItem.fromMap(x)).toList(),
      payments: decodedPayments.map((x) => PaymentEntry.fromMap(x)).toList(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get productsSummary {
    return items.map((item) => "${item.productName} : ${item.quantity}").join("\n");
  }

  double get totalDepositAmount {
    return payments.fold(0, (sum, item) => sum + item.amount);
  }
}
