import 'package:flutter/material.dart';
import '../../data/models/discount_code_model.dart';
import '../../data/repositories/discount_code_api_repository.dart';

class DiscountCodeController extends ChangeNotifier {
  final DiscountCodeApiRepository repository;

  DiscountCodeController({required this.repository});

  List<DiscountCodeModel> codes = [];
  bool isLoading = false;
  String? error;

  Future<void> loadCodes() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      codes = await repository.getAll();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCode(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      await repository.create(data);
      await loadCodes();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCode(int id, Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      await repository.update(id, data);
      await loadCodes();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCode(int id) async {
    try {
      await repository.delete(id);
      codes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
