class PurchaseUser {
  final int id;
  final String name;
  final String post;
  final int idAnbar;
  final String? anbarName;

  const PurchaseUser({
    required this.id,
    required this.name,
    this.post = '',
    required this.idAnbar,
    this.anbarName,
  });

  factory PurchaseUser.fromJson(Map<String, dynamic> json) => PurchaseUser(
        id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        post: json['post']?.toString() ?? '',
        idAnbar: (json['idAnbar'] as num?)?.toInt() ?? int.tryParse(json['idAnbar']?.toString() ?? '') ?? 0,
        anbarName: json['anbarName']?.toString(),
      );
}
