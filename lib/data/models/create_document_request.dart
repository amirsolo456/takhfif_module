class CreateDocumentItemRequest {
  final String idKala;
  final double quantity;
  final double? unitPrice;
  final double? purchasePrice;
  final bool isIncoming;
  final String? description;
  final double? discount;

  const CreateDocumentItemRequest({
    required this.idKala,
    required this.quantity,
    this.unitPrice,
    this.purchasePrice,
    this.isIncoming = false,
    this.description,
    this.discount,
  });

  Map<String, dynamic> toJson() {
    return {
      'idKala': idKala,
      'quantity': quantity,
      if (unitPrice != null) 'unitPrice': unitPrice,
      if (unitPrice != null) 'fi': unitPrice,
      if (unitPrice != null) 'price': unitPrice,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (purchasePrice != null) 'fiKharid': purchasePrice,
      if (discount != null && discount! > 0) 'discount': discount,
      if (discount != null && discount! > 0) 'takhfif': discount,
      if (discount != null && discount! > 0) 'mablaghTakhfif': discount,
      'isIncoming': isIncoming,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
    };
  }
}

class CreateDocumentRequest {
  final int idSal;
  // Nullable so specialized endpoints can let the backend own the type.
  // Purchase endpoint forces SanadType=11 server-side.
  final int? sanadType;
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
    this.sanadType,
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
      if (sanadType != null) 'sanadType': sanadType,
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
