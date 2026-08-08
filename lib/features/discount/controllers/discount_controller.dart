import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/discount_code.dart';
import '../../../data/models/discount_usage_history.dart';
import '../../../data/repositories/discount_repository.dart';
import '../../../core/utils/discount_code_generator.dart';

class DiscountController extends ChangeNotifier {
  final DiscountRepository _repository = DiscountRepository();

  List<DiscountCode> _codes = [];
  List<DiscountUsageHistory> _history = [];
  bool _isLoading = false;

  List<DiscountCode> get codes => _codes;
  List<DiscountUsageHistory> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    _codes = await _repository.getAllDiscountCodes();
    _history = await _repository.getUsageHistory();
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
    String newCode;
    while (true) {
      newCode = DiscountCodeGenerator.generate();
      final existing = await _repository.getDiscountCodeByCode(newCode);
      if (existing == null) break;
    }

    final discount = DiscountCode(
      code: newCode,
      discountType: type,
      discountValue: value,
      startDate: start,
      expirationDate: end,
      usageLimit: limit,
      remainingUsage: limit,
      minimumPurchaseAmount: minPurchase,
      maximumDiscountAmount: maxDiscount,
      createdAt: DateTime.now(),
    );

    await _repository.insertDiscountCode(discount);
    await refreshData();
    return newCode;
  }

  Future<void> consumeCode({
    required String code,
    String? phone,
    String? product,
    required double amount,
    String? description,
  }) async {
    try {
      await _repository.consumeDiscountCode(
        code: code,
        customerPhone: phone,
        purchasedProduct: product,
        purchaseAmount: amount,
        description: description,
      );
      await refreshData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleCodeStatus(DiscountCode code) async {
    final updated = code.copyWith(isActive: !code.isActive);
    await _repository.updateDiscountCode(updated);
    await refreshData();
  }

  Future<void> searchHistory(String query) async {
    _history = await _repository.getUsageHistory(query: query);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
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

        await _repository.clearAll();

        final List codesMap = data['codes'] ?? [];
        final List historyMap = data['history'] ?? [];

        for (var map in codesMap) {
          await _repository.insertDiscountCode(DiscountCode.fromMap(map));
        }

        for (var map in historyMap) {
          await _repository.insertUsageHistory(DiscountUsageHistory.fromMap(map));
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
