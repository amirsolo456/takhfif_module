class KavenegarConfig {
  const KavenegarConfig._();

  // Pass the real key at build time:
  // flutter build apk --dart-define=KAVENEGAR_API_KEY=YOUR_API_KEY
  static const String apiKey = String.fromEnvironment('KAVENEGAR_API_KEY');

  // Optional Kavenegar sender/line. Leave empty to use the account default line.
  static const String sender = String.fromEnvironment('KAVENEGAR_SENDER');

  static const String apiBaseUrl = 'https://api.kavenegar.com/v1';
}
