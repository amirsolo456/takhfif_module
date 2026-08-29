import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../data/models/create_order_request.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/discount_code_model.dart';
import '../../data/repositories/order_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/discount_code_api_repository.dart';

class OrderRegistrationController extends ChangeNotifier {
  final OrderApiRepository _orderRepo;
  final MasterDataRepository _masterDataRepo;
  final DiscountCodeApiRepository _discountRepo;

  OrderRegistrationController({
    required OrderApiRepository orderRepo,
    required MasterDataRepository masterDataRepo,
    required DiscountCodeApiRepository discountRepo,
  })  : _orderRepo = orderRepo,
        _masterDataRepo = masterDataRepo,
        _discountRepo = discountRepo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Person? selectedPerson;
  List<OrderItemEntry> basketItems = [];
  
  String? discountCode;
  ValidateDiscountCodeResponse? discountValidation;

  Future<List<Person>> searchPersons(String query) => _masterDataRepo.searchPersons(query);
  Future<List<Kala>> searchKalas(String query) => _masterDataRepo.searchKalas(query);

  Future<Person?> createPerson(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final person = await _masterDataRepo.createPerson(data);
      selectedPerson = person;
      _isLoading = false;
      notifyListeners();
      return person;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void addToBasket(Kala kala) {
    final existing = basketItems.where((i) => i.kala.id == kala.id).firstOrNull;
    if (existing != null) {
      existing.quantity += 1;
    } else {
      basketItems.add(OrderItemEntry(kala: kala, unitPrice: kala.salePrice ?? 0));
    }
    notifyListeners();
  }

  void removeFromBasket(int index) {
    basketItems.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    basketItems[index].quantity = quantity;
    notifyListeners();
  }

  void updateUnitPrice(int index, double price) {
    basketItems[index].unitPrice = price;
    notifyListeners();
  }

  void updateDiscount(int index, double discount) {
    basketItems[index].discount = discount;
    notifyListeners();
  }

  Future<void> validateDiscount(String code) async {
    if (selectedPerson == null) {
      _error = 'لطفا ابتدا مشتری را انتخاب کنید';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      discountCode = code;
      discountValidation = await _discountRepo.validate(code, selectedPerson!.id, totalBeforeCodeDiscount);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      discountValidation = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  double get totalItemsAmount => basketItems.fold(0, (sum, i) => sum + (i.quantity * i.unitPrice));
  double get totalItemsDiscount => basketItems.fold(0, (sum, i) => sum + i.discount);
  double get totalBeforeCodeDiscount => totalItemsAmount - totalItemsDiscount;
  double get codeDiscountAmount => discountValidation?.discountAmount ?? 0;
  double get finalAmount => totalBeforeCodeDiscount - codeDiscountAmount;

  Future<OrderModel?> submitOrder() async {
    if (selectedPerson == null || basketItems.isEmpty) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nameParts = selectedPerson!.fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final request = CreateOrderRequest(
        firstName: firstName,
        lastName: lastName,
        mobile: selectedPerson!.mobile ?? '',
        address: selectedPerson!.address,
        notes: 'ثبت شده از اپلیکیشن',
        items: basketItems.map((i) => CreateOrderItemRequest(
          kalaId: i.kala.code,
          quantity: i.quantity,
        )).toList(),
      );

      final result = await _orderRepo.createOrder(request);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}

class OrderItemEntry {
  final Kala kala;
  double quantity;
  double unitPrice;
  double discount;

  OrderItemEntry({
    required this.kala,
    this.quantity = 1,
    required this.unitPrice,
    this.discount = 0,
  });

  double get totalPrice => (quantity * unitPrice) - discount;
}
