import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_settings.dart';
import '../models/person.dart';
import '../models/kala.dart';
class MasterDataRepository {
  final String _initialBaseUrl;
  String get baseUrl => ApiSettings.current.baseUrl.isNotEmpty ? ApiSettings.current.baseUrl : _initialBaseUrl;
  MasterDataRepository({required String baseUrl}) : _initialBaseUrl = baseUrl;
  String _normalize(String input) => input.trim().replaceAll('ي', 'ی').replaceAll('ك', 'ک');
  Future<List<Person>> searchPersons(String query) async { final trimmedQuery=_normalize(query); final uri=Uri.parse('$baseUrl/api/customers').replace(queryParameters:{if(trimmedQuery.isNotEmpty)'search':trimmedQuery,'page':'1','pageSize':'50'}); debugPrint('🔍 Searching Persons API: $uri'); final response=await http.get(uri,headers:const{'Accept':'application/json'}); if(response.statusCode<200||response.statusCode>=300) throw Exception('خطای سرور (${response.statusCode})'); final decoded=jsonDecode(response.body); return _extractList(decoded).map((e)=>_personFromCustomerJson(Map<String,dynamic>.from(e))).toList(growable:false); }
  Future<List<Kala>> searchKalas(String query) async { final trimmed=_normalize(query); final uri=Uri.parse('$baseUrl/api/products').replace(queryParameters:{if(trimmed.isNotEmpty)'search':trimmed,'page':'1','pageSize':trimmed.isEmpty?'200':'50'}); final response=await http.get(uri,headers:const{'Accept':'application/json'}); if(response.statusCode<200||response.statusCode>=300) throw Exception('خطای سرور (${response.statusCode})'); final decoded=jsonDecode(response.body); return _extractList(decoded).map((e)=>Kala.fromJson(Map<String,dynamic>.from(e))).toList(growable:false); }
  Future<Person> createPerson(Map<String,dynamic> data) async { final response=await http.post(Uri.parse('$baseUrl/api/customers'),headers:const{'Accept':'application/json','Content-Type':'application/json'},body:jsonEncode(data)); if(response.statusCode<200||response.statusCode>=300)throw Exception('خطا در ثبت مشتری'); final decoded=jsonDecode(response.body) as Map<String,dynamic>; final payload=decoded['data'] is Map?Map<String,dynamic>.from(decoded['data']):decoded; return _personFromCustomerJson(payload); }
  Person _personFromCustomerJson(Map<String,dynamic> json){final name=(json['name']??'').toString().trim();final parts=name.isEmpty?<String>[]:name.split(RegExp(r'\s+'));final type=_toInt(json['idType'],fallback:1);return Person(id:_toInt(json['id']),personType:type,firstName:parts.isNotEmpty?parts.first:'',lastName:parts.length>1?parts.sublist(1).join(' '):'',companyName:type==2?name:null,mobile:json['mobile']?.toString(),phone:json['phone']?.toString(),address:json['address']?.toString(),isActive:true);}
  int _toInt(dynamic v,{int fallback=0})=>v is num?v.toInt():int.tryParse(v?.toString()??'')??fallback;
  List<dynamic> _extractList(dynamic decoded){if(decoded is List)return decoded;if(decoded is Map<String,dynamic>){final data=decoded['data'];if(data is List)return data;final result=decoded['result'];if(result is List)return result;}return const[];}
}
