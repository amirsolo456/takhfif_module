import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sms_model.dart';

class SmsApiRepository {
  final String baseUrl;

  SmsApiRepository({required this.baseUrl});

  Future<SendSmsResponse> sendSms(String mobile, String message, {int? personId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sms/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'message': message,
        'personId': personId,
      }),
    );
    if (response.statusCode == 200) {
      return SendSmsResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('خطا در ارسال پیامک');
  }

  Future<List<SmsLogModel>> getLogs({int? personId}) async {
    final uri = Uri.parse('$baseUrl/api/sms/logs').replace(queryParameters: personId != null ? {'personId': personId.toString()} : null);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SmsLogModel.fromJson(e)).toList();
    }
    throw Exception('خطا در دریافت لاگ‌های پیامک');
  }
}
