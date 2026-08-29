class CreateDocumentItemRequest {
  final String idKala;
  final double quantity;
  final double? unitPrice;
  final bool isIncoming;
  final String? description;

  const CreateDocumentItemRequest({
    required this.idKala,
    required this.quantity,
    this.unitPrice,
    this.isIncoming = false,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'idKala': idKala,
      'quantity': quantity,
      if (unitPrice != null) 'unitPrice': unitPrice,
      'isIncoming': isIncoming,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
    };
  }
}

class CreateDocumentRequest {
  final int idSal;
  final int sanadType;
  final int idAnbar;
  final int idTaraf;
  final int idTarafType;
  final int idMasool;
  final int idSandogh;
  final int idSandoghType;
  final int? idFaktor;
  final String sabtDate;
  final String? des;
  final String? sharh;
  final bool checkStock;
  final List<CreateDocumentItemRequest> items;

  const CreateDocumentRequest({
    required this.idSal,
    required this.sanadType,
    required this.idAnbar,
    required this.idTaraf,
    required this.idTarafType,
    required this.idMasool,
    required this.idSandogh,
    required this.idSandoghType,
    required this.sabtDate,
    required this.items,
    this.idFaktor,
    this.des,
    this.sharh,
    this.checkStock = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'idSal': idSal,
      'sanadType': sanadType,
      'idAnbar': idAnbar,
      'idTaraf': idTaraf,
      'idTarafType': idTarafType,
      'idMasool': idMasool,
      'idSandogh': idSandogh,
      'idSandoghType': idSandoghType,
      if (idFaktor != null) 'idFaktor': idFaktor,
      'sabtDate': sabtDate,
      if (des != null && des!.trim().isNotEmpty) 'des': des,
      if (sharh != null && sharh!.trim().isNotEmpty) 'sharh': sharh,
      'checkStock': checkStock,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
