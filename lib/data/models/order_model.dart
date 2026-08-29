import 'order_item_model.dart';

class OrderModel {
  final int? id;
  final String? orderNumber;

  final String firstName;
  final String lastName;
  final String mobile;
  final String? address;

  final String? paymentDate;
  final double paymentAmount;

  final int status;

  final int? tarafId;
  final String? sanadId;

  final List<OrderItemModel> items;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  int? get personId => tarafId;

  const OrderModel({
    this.id,
    this.orderNumber,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.address,
    this.paymentDate,
    this.paymentAmount = 0,
    this.status = 1,
    this.tarafId,
    this.sanadId,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['orderNumber'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'],
      paymentDate: json['paymentDate'],
      paymentAmount:
          (json['paymentAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 1,
      tarafId: json['tarafId'],
      sanadId: json['sanadId'],
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'address': address,
      'paymentDate': paymentDate,
      'paymentAmount': paymentAmount,
      'status': status,
      'tarafId': tarafId,
      'sanadId': sanadId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
