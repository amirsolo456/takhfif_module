class PurchaseUser {
  final int id;
  final String name;
  final String post;

  const PurchaseUser({
    required this.id,
    required this.name,
    this.post = '',
  });

  factory PurchaseUser.fromJson(Map<String, dynamic> json) => PurchaseUser(
        id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        post: json['post']?.toString() ?? '',
      );
}
