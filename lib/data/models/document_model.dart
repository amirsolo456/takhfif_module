class DocumentItemModel {
  final int id2;
  final String idKala;
  final double quantity;
  final bool isIncoming;
  final double unitPrice;
  final double purchasePrice;
  final double totalAmount;

  const DocumentItemModel({
    required this.id2,
    required this.idKala,
    required this.quantity,
    required this.isIncoming,
    required this.unitPrice,
    required this.purchasePrice,
    required this.totalAmount,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id2: (json['id2'] as num?)?.toInt() ?? (int.tryParse(json['id2']?.toString() ?? '') ?? 0),
      idKala: json['idKala']?.toString() ?? json['id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? (double.tryParse(json['quantity']?.toString() ?? '') ?? 0),
      isIncoming: json['isIncoming'] == true || json['isIncoming'] == 1 || json['isIncoming']?.toString() == 'true',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? (double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? (double.tryParse(json['purchasePrice']?.toString() ?? '') ?? 0),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0),
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
    required this.items,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      idSal: (json['idSal'] as num?)?.toInt() ?? (int.tryParse(json['idSal']?.toString() ?? '') ?? 0),
      id: json['id']?.toString() ?? json['idSanad']?.toString() ?? json['sanadId']?.toString() ?? '',
      sanadType: (json['sanadType'] as num?)?.toInt() ?? (int.tryParse(json['sanadType']?.toString() ?? '') ?? 0),
      idAnbar: (json['idAnbar'] as num?)?.toInt() ?? (int.tryParse(json['idAnbar']?.toString() ?? '') ?? 0),
      idTaraf: (json['idTaraf'] as num?)?.toInt() ?? (int.tryParse(json['idTaraf']?.toString() ?? '') ?? 0),
      idTarafType: (json['idTarafType'] as num?)?.toInt() ?? (int.tryParse(json['idTarafType']?.toString() ?? '') ?? 0),
      idFaktor: (json['idFaktor'] as num?)?.toInt() ?? (int.tryParse(json['idFaktor']?.toString() ?? '') ?? 0),
      sabtDate: json['sabtDate']?.toString() ?? json['date']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0),
      isFinal: json['isFinal'] == true || json['isFinal'] == 1 || json['isFinal']?.toString() == 'true',
      description: json['description']?.toString() ?? json['des']?.toString() ?? json['sharh']?.toString(),
      tarafName: json['tarafName']?.toString() ?? json['customerName']?.toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DocumentItemModel.fromJson)
          .toList(growable: false),
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
