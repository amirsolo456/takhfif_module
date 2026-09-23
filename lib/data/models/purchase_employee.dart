class PurchaseEmployee {
  final int id;
  final String name;
  final String? mobile;
  final bool isActive;

  const PurchaseEmployee({required this.id, required this.name, this.mobile, this.isActive = true});

  factory PurchaseEmployee.fromJson(Map<String, dynamic> json) => PurchaseEmployee(
        id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        mobile: json['mobile']?.toString(),
        isActive: json['isActive'] == true || json['isActive'] == 1 || json['isActive']?.toString() == 'true',
      );
}
