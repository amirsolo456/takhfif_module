class Person {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final String? address;

  Person({
    required this.id,
    this.firstName,
    this.lastName,
    this.mobile,
    this.address,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      mobile: json['mobile'],
      address: json['address'],
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
