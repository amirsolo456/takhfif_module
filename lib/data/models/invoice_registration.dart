
class CreateInvoiceRequest {
  final int personId;
  final int warehouseId;
  final List<CreateInvoiceItemRequest> items;
  final List<CreateInvoicePaymentRequest> payments;
  final bool sendDiscountSms;

  CreateInvoiceRequest({
    required this.personId,
    required this.warehouseId,
    required this.items,
    required this.payments,
    required this.sendDiscountSms,
  });

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'warehouseId': warehouseId,
        'items': items.map((x) => x.toJson()).toList(),
        'payments': payments.map((x) => x.toJson()).toList(),
        'sendDiscountSms': sendDiscountSms,
      };
}

class CreateInvoiceItemRequest {
  final String kalaId;
  final double quantity;
  final double purchasePrice;
  final double salePrice;

  CreateInvoiceItemRequest({
    required this.kalaId,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
  });

  Map<String, dynamic> toJson() => {
        'kalaId': kalaId,
        'quantity': quantity,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
      };
}

class CreateInvoicePaymentRequest {
  final DateTime paymentDate;
  final double amount;

  CreateInvoicePaymentRequest({
    required this.paymentDate,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'paymentDate': paymentDate.toIso8601String(),
        'amount': amount,
      };
}

class CreateInvoiceResponse {
  final int invoiceId;
  final String invoiceNo;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final bool smsSent;
  final String? smsError;

  CreateInvoiceResponse({
    required this.invoiceId,
    required this.invoiceNo,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.smsSent,
    this.smsError,
  });

  factory CreateInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return CreateInvoiceResponse(
      invoiceId: json['invoiceId'],
      invoiceNo: json['invoiceNo'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'],
      smsSent: json['smsSent'],
      smsError: json['smsError'],
    );
  }
}
