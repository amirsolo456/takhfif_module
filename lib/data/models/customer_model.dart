class CustomerModel {
  final int? id;
  final String name;
  final String? address;
  final String? tel;
  final String mobile;

  CustomerModel({
    this.id,
    required this.name,
    this.address,
    this.tel,
    required this.mobile,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'],
      tel: json['tel'],
      mobile: json['mobile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'tel': tel,
      'mobile': mobile,
    };
  }
}
