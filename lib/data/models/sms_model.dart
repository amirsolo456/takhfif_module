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
      id: (json['id'] as num).toInt(),
      personId: (json['personId'] as num?)?.toInt(),
      mobile: json['mobile'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: (json['status'] as num?)?.toInt() ?? 3,
      provider: json['provider'] as String?,
      providerMessageId: json['providerMessageId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SmsProviderStatus {
  final bool configured;
  final String provider;
  final bool hasSendUrl;
  final bool hasApiKey;
  final bool hasSender;

  const SmsProviderStatus({
    required this.configured,
    required this.provider,
    required this.hasSendUrl,
    required this.hasApiKey,
    required this.hasSender,
  });

  factory SmsProviderStatus.fromJson(Map<String, dynamic> json) {
    return SmsProviderStatus(
      configured: json['configured'] == true,
      provider: json['provider'] as String? ?? 'HttpSmsProvider',
      hasSendUrl: json['hasSendUrl'] == true,
      hasApiKey: json['hasApiKey'] == true,
      hasSender: json['hasSender'] == true,
    );
  }
}

class SendSmsResponse {
  final bool success;
  final String message;
  final String? providerMessageId;
  final String? provider;

  SendSmsResponse({
    required this.success,
    required this.message,
    this.providerMessageId,
    this.provider,
  });

  factory SendSmsResponse.fromJson(Map<String, dynamic> json) {
    return SendSmsResponse(
      success: json['success'] == true,
      message: json['message'] as String? ?? 'پاسخ نامشخص از سرویس پیامک.',
      providerMessageId: json['providerMessageId'] as String?,
      provider: json['provider'] as String?,
    );
  }
}
