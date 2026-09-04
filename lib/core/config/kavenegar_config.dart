class KavenegarConfig {
  const KavenegarConfig._();

  static const String _envApiKey = String.fromEnvironment('KAVENEGAR_API_KEY');
  static const String defaultApiKey = '6A596E4A70744252764A4A36546F4A75724334754C62366E436C677839653855614F63386149452F3943383D';

  static String get apiKey => _envApiKey.isNotEmpty ? _envApiKey : defaultApiKey;

  // Optional Kavenegar sender/line. Leave empty to use the account default line.
  static const String sender = String.fromEnvironment('KAVENEGAR_SENDER');

  static const String apiBaseUrl = 'https://api.kavenegar.com/v1';
}
