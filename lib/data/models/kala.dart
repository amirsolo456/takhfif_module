class Kala {
  final String id;
  final String kalaName;
  final double mabFrosh;

  Kala({
    required this.id,
    required this.kalaName,
    required this.mabFrosh,
  });

  factory Kala.fromJson(Map<String, dynamic> json) {
    return Kala(
      id: json['id'],
      kalaName: json['kalaName'] ?? json['name'] ?? '',
      mabFrosh: (json['mabFrosh'] ?? json['price'] ?? 0).toDouble(),
    );
  }
}
