import 'package:flutter/material.dart';
import '../../data/models/document_model.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/discount_code_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/discount_code_api_repository.dart';

class OrderRegistrationController extends ChangeNotifier {
  final DocumentApiRepository _documentRepo;
  final MasterDataRepository _masterDataRepo;
  final DiscountCodeApiRepository _discountRepo;

  OrderRegistrationController({
    required DocumentApiRepository documentRepo,
    required MasterDataRepository masterDataRepo,
    required DiscountCodeApiRepository discountRepo,
  })  : _documentRepo = documentRepo,
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

  int idSal = 1405;
  int sanadType = 12;
  int idAnbar = 1;
  int idMasool = 101;
  int idSandogh = 1;
  int idSandoghType = 1;
  String sabtDate = '';
  String? description;
  String? sharh;
  bool checkStock = true;

  Future<List<Person>> searchPersons(String query) => _masterDataRepo.searchPersons(query);
  Future<List<Kala>> searchKalas(String query) => _masterDataRepo.searchKalas(query);

  Future<Person?> createPerson(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final person = await _masterDataRepo.createPerson(data);
      selectedPerson = person;
      return person;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToBasket(Kala kala) {
    final existing = basketItems.where((i) => i.kala.id == kala.id).firstOrNull;
    if (existing != null) {
      existing.quantity += 1;
    } else {
      basketItems.add(OrderItemEntry(
        kala: kala,
        unitPrice: kala.salePrice ?? 0,
      ));
    }
    notifyListeners();
  }

  void removeFromBasket(int index) {
    basketItems.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    basketItems[index].quantity = quantity < 1 ? 1 : quantity;
    notifyListeners();
  }

  void updateUnitPrice(int index, double price) {
    basketItems[index].unitPrice = price < 0 ? 0 : price;
    notifyListeners();
  }

  void updateDiscount(int index, double discount) {
    basketItems[index].discount = discount < 0 ? 0 : discount;
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
      discountCode = code.trim();
      discountValidation = await _discountRepo.validate(
        discountCode!,
        selectedPerson!.id,
        totalBeforeCodeDiscount,
      );
    } catch (e) {
      _error = e.toString();
      discountValidation = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get totalItemsAmount =>
      basketItems.fold(0, (sum, i) => sum + (i.quantity * i.unitPrice));

  double get totalItemsDiscount =>
      basketItems.fold(0, (sum, i) => sum + i.discount);

  double get totalBeforeCodeDiscount =>
      totalItemsAmount - totalItemsDiscount;

  double get codeDiscountAmount => discountValidation?.discountAmount ?? 0;

  double get finalAmount =>
      (totalBeforeCodeDiscount - codeDiscountAmount).clamp(0, double.infinity);

  Future<DocumentModel?> submitDocument() async {
    if (selectedPerson == null) {
      _error = 'لطفا ابتدا مشتری را انتخاب کنید';
      notifyListeners();
      return null;
    }
    if (basketItems.isEmpty) {
      _error = 'سبد خرید خالی است';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (sabtDate.trim().isEmpty) {
        final now = DateTime.now();
        sabtDate = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
      }

      final request = CreateDocumentRequest(
        idSal: idSal,
        sanadType: sanadType,
        idAnbar: idAnbar,
        idTaraf: selectedPerson!.id,
        idTarafType: selectedPerson!.personType,
        idMasool: idMasool,
        idSandogh: idSandogh,
        idSandoghType: idSandoghType,
        sabtDate: sabtDate,
        des: description ?? 'فاکتور فروش',
        sharh: sharh,
        checkStock: checkStock,
        items: basketItems.map((item) => CreateDocumentItemRequest(
          idKala: item.kala.code,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          isIncoming: false,
          description: null,
        )).toList(),
      );

      return await _documentRepo.createDocument(request);
    } on DocumentApiException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  double get totalPrice =>
      (quantity * unitPrice) - discount;
}
