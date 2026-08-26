import 'package:flutter/material.dart';
import '../../data/models/invoice_registration.dart';
import '../../data/repositories/invoice_api_repository.dart';

class InvoiceRegistrationController extends ChangeNotifier {
  final InvoiceApiRepository _repository;

  InvoiceRegistrationController({required InvoiceApiRepository repository}) : _repository = repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  CreateInvoiceResponse? _lastResponse;
  CreateInvoiceResponse? get lastResponse => _lastResponse;

  Future<bool> submitInvoice(CreateInvoiceRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lastResponse = await _repository.createInvoice(request);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
