class KavenegarConfig {
  const KavenegarConfig._();

  static const String _envApiKey = String.fromEnvironment('KAVENEGAR_API_KEY');
  static const String defaultApiKey = '';

  static String get apiKey => _envApiKey;

  // Kavenegar sender line shown in the account's Java web-service example.
  static const String _envSender = String.fromEnvironment('KAVENEGAR_SENDER');
  static const String defaultSender = '2000660110';

  static String get sender => _envSender.isNotEmpty ? _envSender : defaultSender;

  static const String apiBaseUrl = 'https://api.kavenegar.com/v1';
}
