import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../data/models/document_model.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/discount_code_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/discount_code_api_repository.dart';

class OrderRegistrationController extends ChangeNotifier {
  final DocumentApiRepository documentRepo;
  final MasterDataRepository masterDataRepo;
  final DiscountCodeApiRepository discountRepo;
  OrderRegistrationController({required this.documentRepo, required this.masterDataRepo, required this.discountRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  Person? selectedPerson;
  List<OrderItemEntry> basketItems = [];
  String? discountCode;
  ValidateDiscountCodeResponse? discountValidation;
  int idSal = 1405, sanadType = 12, idAnbar = 1, idMasool = 101, idSandogh = 1, idSandoghType = 1;
  String sabtDate = '';
  String? description, sharh;
  bool checkStock = true;

  Future<List<Person>> searchPersons(String query) => masterDataRepo.searchPersons(query);
  Future<List<Kala>> searchKalas(String query) => masterDataRepo.searchKalas(query);
  Future<Kala> createKala({required String name, double salePrice = 0, double purchasePrice = 0, String? barcode}) => masterDataRepo.createKala(name: name, salePrice: salePrice, purchasePrice: purchasePrice, barcode: barcode);

  Future<Person?> createPerson(Map<String, dynamic> data) async {
    _isLoading = true; _error = null; notifyListeners();
    try { final person = await masterDataRepo.createPerson(data); selectedPerson = person; return person; }
    catch (e) { _error = e.toString(); return null; }
    finally { _isLoading = false; notifyListeners(); }
  }

  void addToBasket(Kala kala) { final existing = basketItems.where((i) => i.kala.id == kala.id).firstOrNull; if (existing != null) { existing.quantity += 1; } else { basketItems.add(OrderItemEntry(kala: kala, unitPrice: kala.salePrice ?? 0, purchasePrice: kala.purchasePrice ?? 0)); } notifyListeners(); }
  void removeFromBasket(int index) { basketItems.removeAt(index); notifyListeners(); }
  void updateQuantity(int index, double quantity) { basketItems[index].quantity = quantity < 1 ? 1 : quantity; notifyListeners(); }
  void updateUnitPrice(int index, double price) { basketItems[index].unitPrice = price < 0 ? 0 : price; notifyListeners(); }
  void updatePurchasePrice(int index, double price) { basketItems[index].purchasePrice = price < 0 ? 0 : price; notifyListeners(); }
  void updateDiscount(int index, double discount) { basketItems[index].discount = discount < 0 ? 0 : discount; notifyListeners(); }

  Future<void> validateDiscount(String code) async {
    if (selectedPerson == null) { _error = 'لطفا ابتدا مشتری را انتخاب کنید'; notifyListeners(); return; }
    _isLoading = true; _error = null; notifyListeners();
    try { discountCode = code.trim(); discountValidation = await discountRepo.validate(discountCode!, selectedPerson!.id, totalBeforeCodeDiscount); }
    catch (e) { _error = e.toString(); discountValidation = null; }
    finally { _isLoading = false; notifyListeners(); }
  }

  double get totalItemsAmount => basketItems.fold(0, (sum, i) => sum + i.quantity * i.unitPrice);
  double get totalItemsDiscount => basketItems.fold(0, (sum, i) => sum + i.discount);
  double get totalBeforeCodeDiscount => totalItemsAmount - totalItemsDiscount;
  double get codeDiscountAmount => discountValidation?.discountAmount ?? 0;
  double get finalAmount => (totalBeforeCodeDiscount - codeDiscountAmount).clamp(0, double.infinity);

  CreateDocumentRequest buildRequest({int? forcedSanadType}) {
    final type = forcedSanadType ?? sanadType;
    final effectiveDate = sabtDate.trim().isEmpty
        ? (() { final now = DateTime.now(); final j = Jalali.fromDateTime(now); return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}'; })()
        : sabtDate;
    sabtDate = effectiveDate;
    return CreateDocumentRequest(
      idSal: idSal, sanadType: type, idAnbar: idAnbar,
      idTaraf: selectedPerson!.id, idTarafType: selectedPerson!.personType, idMasool: idMasool,
      idSandogh: idSandogh, idSandoghType: idSandoghType, sabtDate: effectiveDate,
      des: description ?? (type == 113 ? 'فروش از انبار همکار' : 'فاکتور فروش'), sharh: sharh,
      checkStock: type == 113 ? false : checkStock,
      items: basketItems.map((item) => CreateDocumentItemRequest(
        idKala: item.kala.code.isNotEmpty ? item.kala.code : item.kala.id,
        quantity: item.quantity, unitPrice: item.unitPrice, purchasePrice: item.purchasePrice,
        isIncoming: false, description: null,
      )).toList(),
    );
  }

  Future<DocumentModel?> submitDocument() async {
    if (selectedPerson == null) { _error = 'لطفا ابتدا مشتری را انتخاب کنید'; notifyListeners(); return null; }
    if (basketItems.isEmpty) { _error = 'سبد خرید خالی است'; notifyListeners(); return null; }
    _isLoading = true; _error = null; notifyListeners();
    try { return await documentRepo.createDocument(buildRequest()); }
    on DocumentApiException catch (e) { _error = e.message; rethrow; }
    catch (e) { _error = e.toString(); rethrow; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<DocumentModel?> submitPartnerSaleDocument() async {
    if (selectedPerson == null) { _error = 'لطفا ابتدا مشتری را انتخاب کنید'; notifyListeners(); return null; }
    if (basketItems.isEmpty) { _error = 'سبد خرید خالی است'; notifyListeners(); return null; }
    _isLoading = true; _error = null; notifyListeners();
    try { return await documentRepo.createPartnerSaleDocument(request: buildRequest(forcedSanadType: 113)); }
    on DocumentApiException catch (e) { _error = e.message; rethrow; }
    catch (e) { _error = e.toString(); rethrow; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<OrderModel?> submitOrder() async {
    final document = await submitDocument(); if (document == null) return null;
    final items = document.items.map((item) { final matched = basketItems.where((x) => x.kala.code == item.idKala).firstOrNull; return OrderItemModel(kalaId: item.idKala, kalaName: matched?.kala.name ?? item.idKala, quantity: item.quantity, unitPrice: item.unitPrice, totalPrice: item.totalAmount); }).toList(growable: false);
    return OrderModel(id: int.tryParse(document.id), orderNumber: document.idFaktor.toString(), firstName: selectedPerson?.firstName ?? '', lastName: selectedPerson?.lastName ?? '', mobile: selectedPerson?.mobile ?? '', address: selectedPerson?.address, paymentAmount: document.totalAmount, status: document.isFinal ? 5 : 1, tarafId: document.idTaraf, sanadId: document.id, items: items);
  }
}

class OrderItemEntry {
  final Kala kala; double quantity; double unitPrice; double purchasePrice; double discount;
  OrderItemEntry({required this.kala, this.quantity = 1, required this.unitPrice, this.purchasePrice = 0, this.discount = 0});
  double get totalPrice => quantity * unitPrice - discount;
}
