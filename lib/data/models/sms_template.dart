class SmsTemplate {
  final int? id;
  final String name;
  final String body;

  SmsTemplate({
    this.id,
    required this.name,
    required this.body,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'body': body,
    };
  }

  factory SmsTemplate.fromMap(Map<String, dynamic> map) {
    return SmsTemplate(
      id: map['id'],
      name: map['name'],
      body: map['body'],
    );
  }
}
