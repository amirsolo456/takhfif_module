class CreateOrderItemRequest {
  final String kalaId;
  final double quantity;

  CreateOrderItemRequest({
    required this.kalaId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'kalaId': kalaId,
      'quantity': quantity,
    };
  }
}

class CreateOrderRequest {
  final String firstName;
  final String lastName;
  final String mobile;
  final String? address;
  final String? paymentDate;
  final double? paymentAmount;
  final String? notes;
  final List<CreateOrderItemRequest> items;

  CreateOrderRequest({
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.address,
    this.paymentDate,
    this.paymentAmount,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'address': address,
      'paymentDate': paymentDate,
      'paymentAmount': paymentAmount,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
