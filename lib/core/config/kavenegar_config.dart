class KavenegarConfig {
  const KavenegarConfig._();

  static const String _envApiKey = String.fromEnvironment('KAVENEGAR_API_KEY');
  static const String defaultApiKey = String.fromEnvironment('KAVENEGAR_API_KEY');

  static String get apiKey => _envApiKey.isNotEmpty ? _envApiKey : defaultApiKey;

  // Kavenegar sender line verified by the user.
  static const String _envSender = String.fromEnvironment('KAVENEGAR_SENDER');
  static const String defaultSender = '09192410207';

  static String get sender => _envSender.isNotEmpty ? _envSender : defaultSender;

  static const String apiBaseUrl = 'https://api.kavenegar.com/v1';
}
