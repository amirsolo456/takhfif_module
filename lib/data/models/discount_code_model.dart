class DiscountCodeModel {
  final int id;
  final String code;
  final String? title;
  final int type; // 1: Percentage, 2: FixedAmount
  final double value;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final int? usageLimit;
  final int usedCount;
  final int? perCustomerLimit;
  final bool isActive;
  final String? description;
  final DateTime createdAt;

  DiscountCodeModel({
    required this.id,
    required this.code,
    this.title,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscountAmount,
    required this.startDate,
    this.endDate,
    this.usageLimit,
    required this.usedCount,
    this.perCustomerLimit,
    required this.isActive,
    this.description,
    required this.createdAt,
  });

  factory DiscountCodeModel.fromJson(Map<String, dynamic> json) {
    return DiscountCodeModel(
      id: json['id'] as int,
      code: json['code'] as String,
      title: json['title'] as String?,
      type: json['type'] as int,
      value: (json['value'] as num).toDouble(),
      minOrderAmount: json['minOrderAmount'] != null ? (json['minOrderAmount'] as num).toDouble() : null,
      maxDiscountAmount: json['maxDiscountAmount'] != null ? (json['maxDiscountAmount'] as num).toDouble() : null,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      usageLimit: json['usageLimit'] as int?,
      usedCount: json['usedCount'] as int,
      perCustomerLimit: json['perCustomerLimit'] as int?,
      isActive: json['isActive'] as bool,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'type': type,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'perCustomerLimit': perCustomerLimit,
      'isActive': isActive,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ValidateDiscountCodeResponse {
  final bool isValid;
  final double discountAmount;
  final double finalAmount;
  final String message;

  ValidateDiscountCodeResponse({
    required this.isValid,
    required this.discountAmount,
    required this.finalAmount,
    required this.message,
  });

  factory ValidateDiscountCodeResponse.fromJson(Map<String, dynamic> json) {
    return ValidateDiscountCodeResponse(
      isValid: json['isValid'] as bool,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      message: json['message'] as String,
    );
  }
}
