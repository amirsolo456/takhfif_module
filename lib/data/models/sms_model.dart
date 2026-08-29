class SmsLogModel {
  final int id;
  final int? personId;
  final String mobile;
  final String message;
  final int status; // 1: Pending, 2: Sent, 3: Failed
  final String? provider;
  final String? providerMessageId;
  final String? errorMessage;
  final DateTime createdAt;

  SmsLogModel({
    required this.id,
    this.personId,
    required this.mobile,
    required this.message,
    required this.status,
    this.provider,
    this.providerMessageId,
    this.errorMessage,
    required this.createdAt,
  });

  factory SmsLogModel.fromJson(Map<String, dynamic> json) {
    return SmsLogModel(
      id: json['id'] as int,
      personId: json['personId'] as int?,
      mobile: json['mobile'] as String,
      message: json['message'] as String,
      status: json['status'] as int,
      provider: json['provider'] as String?,
      providerMessageId: json['providerMessageId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SendSmsResponse {
  final bool success;
  final String message;
  final String? providerMessageId;

  SendSmsResponse({
    required this.success,
    required this.message,
    this.providerMessageId,
  });

  factory SendSmsResponse.fromJson(Map<String, dynamic> json) {
    return SendSmsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      providerMessageId: json['providerMessageId'] as String?,
    );
  }
}
