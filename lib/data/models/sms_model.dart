class SmsLogModel {
  final int id;
  final int? personId;
  final int? idSal;
  final String? idSanad;
  final String mobile;
  final String message;
  final int status;
  final String? provider;
  final String? providerMessageId;
  final int? providerStatus;
  final String? providerStatusText;
  final String? errorMessage;
  final DateTime? lastStatusCheckedAt;
  final DateTime createdAt;

  SmsLogModel({required this.id, this.personId, this.idSal, this.idSanad, required this.mobile, required this.message, required this.status, this.provider, this.providerMessageId, this.providerStatus, this.providerStatusText, this.errorMessage, this.lastStatusCheckedAt, required this.createdAt});

  factory SmsLogModel.fromJson(Map<String, dynamic> json) => SmsLogModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    personId: (json['personId'] as num?)?.toInt(),
    idSal: (json['idSal'] as num?)?.toInt(),
    idSanad: json['idSanad']?.toString(),
    mobile: json['mobile']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    status: (json['status'] as num?)?.toInt() ?? 0,
    provider: json['provider']?.toString(),
    providerMessageId: json['providerMessageId']?.toString(),
    providerStatus: (json['providerStatus'] as num?)?.toInt(),
    providerStatusText: json['providerStatusText']?.toString(),
    errorMessage: json['errorMessage']?.toString(),
    lastStatusCheckedAt: json['lastStatusCheckedAt'] == null ? null : DateTime.tryParse(json['lastStatusCheckedAt'].toString()),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

class SendSmsResponse {
  final bool success;
  final String message;
  final String? providerMessageId;
  const SendSmsResponse({required this.success, required this.message, this.providerMessageId});
  factory SendSmsResponse.fromJson(Map<String, dynamic> json) => SendSmsResponse(
    success: json['success'] == true,
    message: json['message']?.toString() ?? json['statusText']?.toString() ?? '',
    providerMessageId: json['providerMessageId']?.toString(),
  );
}

class OrderRegistrationSmsResponse {
  final bool smsSent;
  final String status;
  final String statusText;
  final String? providerMessageId;
  final int? providerStatus;
  final String? discountCode;
  final String? template;

  const OrderRegistrationSmsResponse({required this.smsSent, required this.status, required this.statusText, this.providerMessageId, this.providerStatus, this.discountCode, this.template});

  factory OrderRegistrationSmsResponse.fromJson(Map<String, dynamic> json) => OrderRegistrationSmsResponse(
    smsSent: json['smsSent'] == true,
    status: json['status']?.toString() ?? 'not_sent',
    statusText: json['statusText']?.toString() ?? json['message']?.toString() ?? '',
    providerMessageId: json['providerMessageId']?.toString(),
    providerStatus: (json['providerStatus'] as num?)?.toInt(),
    discountCode: json['discountCode']?.toString(),
    template: json['template']?.toString(),
  );
}

class OrderRegistrationSmsStatus {
  final String idSanad;
  final bool smsSent;
  final String status;
  final String statusText;
  final String? providerMessageId;
  const OrderRegistrationSmsStatus({required this.idSanad, required this.smsSent, required this.status, required this.statusText, this.providerMessageId});
  factory OrderRegistrationSmsStatus.fromJson(Map<String, dynamic> json) => OrderRegistrationSmsStatus(
    idSanad: json['idSanad']?.toString() ?? '',
    smsSent: json['smsSent'] == true,
    status: json['status']?.toString() ?? 'not_sent',
    statusText: json['statusText']?.toString() ?? '',
    providerMessageId: json['providerMessageId']?.toString(),
  );
}
