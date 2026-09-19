class DocumentItemModel {
  final int id2;
  final String idKala;
  final String? kalaName;
  final double quantity;
  final bool isIncoming;
  final double unitPrice;
  final double purchasePrice;
  final double discount;
  final double totalAmount;

  const DocumentItemModel({
    required this.id2,
    required this.idKala,
    this.kalaName,
    required this.quantity,
    required this.isIncoming,
    required this.unitPrice,
    required this.purchasePrice,
    this.discount = 0,
    required this.totalAmount,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id2: (json['id2'] as num?)?.toInt() ??
          (json['id_2'] as num?)?.toInt() ??
          (int.tryParse(json['id2']?.toString() ?? json['id_2']?.toString() ?? '') ?? 0),
      idKala: json['idKala']?.toString() ??
          json['id']?.toString() ??
          json['kalaId']?.toString() ??
          json['codeKala']?.toString() ??
          json['id_kala']?.toString() ??
          json['kala_id']?.toString() ??
          '',
      kalaName: json['kalaName']?.toString() ??
          json['nameKala']?.toString() ??
          json['kala_name']?.toString() ??
          json['name_kala']?.toString() ??
          json['productName']?.toString() ??
          json['name']?.toString() ??
          json['title']?.toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ??
          (json['tedad'] as num?)?.toDouble() ??
          (json['count'] as num?)?.toDouble() ??
          (json['qty'] as num?)?.toDouble() ??
          (double.tryParse(json['quantity']?.toString() ?? json['tedad']?.toString() ?? json['count']?.toString() ?? json['qty']?.toString() ?? '') ?? 0),
      isIncoming: json['isIncoming'] == true ||
          json['isIncoming'] == 1 ||
          json['isIncoming']?.toString() == 'true' ||
          json['is_incoming'] == true ||
          json['is_incoming'] == 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ??
          (json['fi'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          (json['unit_price'] as num?)?.toDouble() ??
          (double.tryParse(json['unitPrice']?.toString() ?? json['fi']?.toString() ?? json['price']?.toString() ?? json['unit_price']?.toString() ?? '') ?? 0),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ??
          (json['purchase_price'] as num?)?.toDouble() ??
          (json['fiKharid'] as num?)?.toDouble() ??
          (double.tryParse(json['purchasePrice']?.toString() ?? json['purchase_price']?.toString() ?? json['fiKharid']?.toString() ?? '') ?? 0),
      discount: (json['discount'] as num?)?.toDouble() ??
          (json['takhfif'] as num?)?.toDouble() ??
          (json['mablaghTakhfif'] as num?)?.toDouble() ??
          (json['discountAmount'] as num?)?.toDouble() ??
          (json['mablagh_takhfif'] as num?)?.toDouble() ??
          (json['fiTakhfif'] as num?)?.toDouble() ??
          (double.tryParse(json['discount']?.toString() ?? json['takhfif']?.toString() ?? json['mablaghTakhfif']?.toString() ?? json['discountAmount']?.toString() ?? json['mablagh_takhfif']?.toString() ?? '') ?? 0),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['mablagh'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          (double.tryParse(json['totalAmount']?.toString() ?? json['mablagh']?.toString() ?? json['total']?.toString() ?? json['total_amount']?.toString() ?? '') ?? 0),
    );
  }
}

class DocumentModel {
  final int idSal;
  final String id;
  final int sanadType;
  final int idAnbar;
  final int idTaraf;
  final int idTarafType;
  final int idFaktor;
  final String sabtDate;
  final double totalAmount;
  final bool isFinal;
  final String? description;
  final String? tarafName;
  final String? smsStatus;
  final List<DocumentItemModel> items;

  const DocumentModel({
    required this.idSal,
    required this.id,
    required this.sanadType,
    required this.idAnbar,
    required this.idTaraf,
    required this.idTarafType,
    required this.idFaktor,
    required this.sabtDate,
    required this.totalAmount,
    required this.isFinal,
    required this.description,
    required this.tarafName,
    this.smsStatus,
    required this.items,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['details'] ?? json['rows'] ?? json['documentItems'] ?? json['kalaList'] ?? json[' اقلام '];
    final itemsList = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().map(DocumentItemModel.fromJson).toList(growable: false)
        : const <DocumentItemModel>[];

    return DocumentModel(
      idSal: (json['idSal'] as num?)?.toInt() ??
          (json['id_sal'] as num?)?.toInt() ??
          (int.tryParse(json['idSal']?.toString() ?? json['id_sal']?.toString() ?? '') ?? 0),
      id: json['id']?.toString() ??
          json['idSanad']?.toString() ??
          json['sanadId']?.toString() ??
          json['id_sanad']?.toString() ??
          '',
      sanadType: (json['sanadType'] as num?)?.toInt() ??
          (json['sanad_type'] as num?)?.toInt() ??
          (json['type'] as num?)?.toInt() ??
          (int.tryParse(json['sanadType']?.toString() ?? json['sanad_type']?.toString() ?? json['type']?.toString() ?? '') ?? 0),
      idAnbar: (json['idAnbar'] as num?)?.toInt() ??
          (json['id_anbar'] as num?)?.toInt() ??
          (int.tryParse(json['idAnbar']?.toString() ?? json['id_anbar']?.toString() ?? '') ?? 0),
      idTaraf: (json['idTaraf'] as num?)?.toInt() ??
          (json['id_taraf'] as num?)?.toInt() ??
          (int.tryParse(json['idTaraf']?.toString() ?? json['id_taraf']?.toString() ?? '') ?? 0),
      idTarafType: (json['idTarafType'] as num?)?.toInt() ??
          (json['id_taraf_type'] as num?)?.toInt() ??
          (int.tryParse(json['idTarafType']?.toString() ?? json['id_taraf_type']?.toString() ?? '') ?? 0),
      idFaktor: (json['idFaktor'] as num?)?.toInt() ??
          (json['factorId'] as num?)?.toInt() ??
          (json['factorNumber'] as num?)?.toInt() ??
          (json['id_faktor'] as num?)?.toInt() ??
          (int.tryParse(json['idFaktor']?.toString() ?? json['factorId']?.toString() ?? json['factorNumber']?.toString() ?? json['id_faktor']?.toString() ?? '') ?? 0),
      sabtDate: json['sabtDate']?.toString() ??
          json['date']?.toString() ??
          json['createdAt']?.toString() ??
          json['sabt_date']?.toString() ??
          json['tarikh']?.toString() ??
          '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          (json['mablagh'] as num?)?.toDouble() ??
          (double.tryParse(json['totalAmount']?.toString() ?? json['total_amount']?.toString() ?? json['total']?.toString() ?? json['mablagh']?.toString() ?? '') ?? 0),
      isFinal: json['isFinal'] == true ||
          json['isFinal'] == 1 ||
          json['isFinal']?.toString() == 'true' ||
          json['is_final'] == true ||
          json['is_final'] == 1,
      description: json['description']?.toString() ??
          json['des']?.toString() ??
          json['sharh']?.toString() ??
          json['tozihat']?.toString(),
      tarafName: json['tarafName']?.toString() ??
          json['customerName']?.toString() ??
          json['personName']?.toString() ??
          json['taraf_name']?.toString() ??
          json['taraf']?.toString(),
      smsStatus: json['smsStatus']?.toString(),
      items: itemsList,
    );
  }
}

class DocumentApiResponse {
  final bool success;
  final String code;
  final String message;
  final DocumentModel? data;
  final dynamic errors;
  final dynamic warnings;
  final String? traceId;

  const DocumentApiResponse({
    required this.success,
    required this.code,
    required this.message,
    required this.data,
    required this.errors,
    required this.warnings,
    required this.traceId,
  });

  factory DocumentApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return DocumentApiResponse(
      success: json['success'] as bool? ?? (json['isSuccess'] as bool? ?? false),
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      data: data is Map<String, dynamic> ? DocumentModel.fromJson(data) : null,
      errors: json['errors'],
      warnings: json['warnings'],
      traceId: json['traceId']?.toString(),
    );
  }
}

class DocumentHistoryApiResponse {
  final bool success;
  final String code;
  final String message;
  final List<DocumentModel> data;
  final dynamic errors;
  final dynamic warnings;
  final String? traceId;

  const DocumentHistoryApiResponse({
    required this.success,
    required this.code,
    required this.message,
    required this.data,
    required this.errors,
    required this.warnings,
    required this.traceId,
  });

  factory DocumentHistoryApiResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return DocumentHistoryApiResponse(
      success: json['success'] as bool? ?? (json['isSuccess'] as bool? ?? false),
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      data: rawData is List
          ? rawData.whereType<Map<String, dynamic>>().map(DocumentModel.fromJson).toList(growable: false)
          : const [],
      errors: json['errors'],
      warnings: json['warnings'],
      traceId: json['traceId']?.toString(),
    );
  }
}
