import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/discount_code.dart';
import '../../data/models/discount_usage_history.dart';
import '../../domain/services/discount_service.dart';

class DiscountController extends ChangeNotifier {
  final DiscountService _service = DiscountService();

  List<DiscountCode> _codes = [];
  List<DiscountUsageHistory> _history = [];
  bool _isLoading = false;

  List<DiscountCode> get codes => _codes;
  List<DiscountUsageHistory> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _service.init();
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    _codes = await _service.getAllCodes();
    _history = await _service.getHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> createDiscount({
    required DiscountType type,
    required double value,
    required DateTime start,
    required DateTime end,
    required int limit,
    double? minPurchase,
    double? maxDiscount,
  }) async {
    final code = await _service.createDiscount(
      type: type,
      value: value,
      start: start,
      end: end,
      limit: limit,
      minPurchase: minPurchase,
      maxDiscount: maxDiscount,
    );
    await refreshData();
    return code;
  }

  Future<void> consumeCode({
    required String code,
    String? phone,
    String? product,
    required double amount,
    String? description,
  }) async {
    try {
      await _service.consumeCode(
        code: code,
        phone: phone,
        product: product,
        amount: amount,
        description: description,
      );
      await refreshData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleCodeStatus(DiscountCode code) async {
    await _service.toggleStatus(code);
    await refreshData();
  }

  Future<void> searchHistory(String query) async {
    _history = await _service.getHistory(query: query);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    await refreshData();
  }

  Future<String?> exportData() async {
    final data = {
      'codes': _codes.map((e) => e.toMap()).toList(),
      'history': _history.map((e) => e.toMap()).toList(),
    };

    final jsonString = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'discount_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);
    return file.path;
  }

  Future<bool> importData() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        await _service.clearAll();

        final List codesMap = data['codes'] ?? [];
        final List historyMap = data['history'] ?? [];

        for (var map in codesMap) {
          await _service.insertCode(DiscountCode.fromMap(map));
        }

        for (var map in historyMap) {
          await _service.insertHistory(DiscountUsageHistory.fromMap(map));
        }

        await refreshData();
        return true;
      }
    } catch (e) {
      debugPrint('Import error: $e');
    }
    return false;
  }
}
