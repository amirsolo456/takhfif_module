class Anbar {
  final int id;
  final String anabrName;

  Anbar({
    required this.id,
    required this.anabrName,
  });

  factory Anbar.fromJson(Map<String, dynamic> json) {
    return Anbar(
      id: json['id'],
      anabrName: json['anabrName'] ?? json['name'] ?? '',
    );
  }
}
