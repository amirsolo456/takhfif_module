class Person {
  final int id;
  final int personType;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? mobile;
  final String? phone;
  final String? nationalId;
  final String? address;
  final bool isActive;

  Person({
    required this.id,
    this.personType = 1,
    this.firstName,
    this.lastName,
    this.companyName,
    this.mobile,
    this.phone,
    this.nationalId,
    this.address,
    this.isActive = true,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      personType: json['personType'] ?? 1,
      firstName: json['firstName'],
      lastName: json['lastName'],
      companyName: json['companyName'],
      mobile: json['mobile'],
      phone: json['phone'],
      nationalId: json['nationalId'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
    );
  }

  String get fullName {
    if (companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }
}
