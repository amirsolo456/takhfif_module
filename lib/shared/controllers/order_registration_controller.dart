import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/config/api_settings.dart';
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
import '../../data/repositories/sms_api_repository.dart';

class OrderRegistrationController extends ChangeNotifier {
  final DocumentApiRepository documentRepo;
  final MasterDataRepository masterDataRepo;
  final DiscountCodeApiRepository discountRepo;
  late final SmsApiRepository smsRepo;

  bool lastOrderSmsSent = false;
  String? lastOrderSmsMessage;
  String? lastOrderSmsDiscountCode;

  OrderRegistrationController({required this.documentRepo, required this.masterDataRepo, required this.discountRepo}) {
    smsRepo = SmsApiRepository(baseUrl: ApiSettings.current.baseUrl);
  }

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
  void updateLineTotal(int index, double lineTotal) {
    final entry = basketItems[index];
    if (entry.quantity <= 0) return;
    final target = lineTotal < 0 ? 0.0 : lineTotal;
    entry.unitPrice = (target + entry.discount) / entry.quantity;
    notifyListeners();
  }

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

    final totalBeforeCode = totalBeforeCodeDiscount;
    final codeDiscount = codeDiscountAmount;

    final items = basketItems.map((item) {
      final lineNetBeforeCode = (item.quantity * item.unitPrice) - item.discount;
      double effectiveUnitPrice = item.unitPrice;
      double totalItemDiscount = item.discount;

      if (item.quantity > 0) {
        double lineNetFinal = lineNetBeforeCode;
        if (codeDiscount > 0 && totalBeforeCode > 0) {
          final proportion = lineNetBeforeCode / totalBeforeCode;
          final itemCodeDiscount = codeDiscount * proportion;
          totalItemDiscount += itemCodeDiscount;
          lineNetFinal = (lineNetBeforeCode - itemCodeDiscount).clamp(0, double.infinity);
        }
        effectiveUnitPrice = (lineNetFinal / item.quantity).clamp(0, double.infinity);
      }

      return CreateDocumentItemRequest(
        idKala: item.kala.code.isNotEmpty ? item.kala.code : item.kala.id,
        quantity: item.quantity,
        unitPrice: effectiveUnitPrice,
        purchasePrice: item.purchasePrice,
        discount: totalItemDiscount > 0 ? totalItemDiscount : null,
        isIncoming: false,
        description: null,
      );
    }).toList();

    String? formattedDes = description;
    if (discountCode != null && discountCode!.isNotEmpty && codeDiscount > 0) {
      final codeNote = 'کد تخفیف: $discountCode';
      formattedDes = formattedDes != null && formattedDes.isNotEmpty ? '$formattedDes ($codeNote)' : codeNote;
    }

    return CreateDocumentRequest(
      idSal: idSal, sanadType: type, idAnbar: idAnbar,
      idTaraf: selectedPerson!.id, idTarafType: selectedPerson!.personType, idMasool: idMasool,
      idSandogh: idSandogh, idSandoghType: idSandoghType, sabtDate: effectiveDate,
      des: formattedDes ?? (type == 113 ? 'فروش از انبار همکار' : 'فاکتور فروش'), sharh: sharh,
      checkStock: type == 113 ? false : checkStock,
      items: items,
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

  Future<void> _sendRegistrationSms(DocumentModel document) async {
    lastOrderSmsSent = false;
    lastOrderSmsMessage = null;
    lastOrderSmsDiscountCode = null;
    final person = selectedPerson;
    final mobile = person?.mobile?.trim();
    if (person == null || mobile == null || mobile.isEmpty || document.id.isEmpty || document.idFaktor <= 0) {
      lastOrderSmsMessage = 'شماره موبایل یا اطلاعات سند برای ارسال پیامک کامل نیست.';
      return;
    }
    try {
      final result = await smsRepo.sendOrderRegistrationSms(
        idSal: document.idSal,
        idSanad: document.id,
        personId: person.id,
        mobile: mobile,
        factorNumber: document.idFaktor,
        totalAmount: document.totalAmount,
        discountCode: discountCode,
      );
      lastOrderSmsSent = result.smsSent;
      lastOrderSmsMessage = result.statusText;
      lastOrderSmsDiscountCode = result.discountCode;
    } catch (e) {
      lastOrderSmsMessage = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<OrderModel?> submitOrder() async {
    if (discountCode != null && discountCode!.isNotEmpty && discountValidation?.isValid == true && selectedPerson != null) {
      try {
        await discountRepo.consume(discountCode!, selectedPerson!.id, totalBeforeCodeDiscount);
      } catch (_) {}
    }

    final document = await submitDocument();
    if (document == null) return null;

    // SMS is sent after the document is safely persisted. A failed SMS must never fail the order.
    await _sendRegistrationSms(document);

    final items = document.items.map((item) {
      final matched = basketItems.where((x) => x.kala.code == item.idKala).firstOrNull;
      return OrderItemModel(kalaId: item.idKala, kalaName: matched?.kala.name ?? item.idKala, quantity: item.quantity, unitPrice: item.unitPrice, totalPrice: item.totalAmount);
    }).toList(growable: false);
    return OrderModel(id: int.tryParse(document.id), orderNumber: document.idFaktor.toString(), firstName: selectedPerson?.firstName ?? '', lastName: selectedPerson?.lastName ?? '', mobile: selectedPerson?.mobile ?? '', address: selectedPerson?.address, paymentAmount: document.totalAmount, status: document.isFinal ? 5 : 1, tarafId: document.idTaraf, sanadId: document.id, items: items);
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
}

class OrderItemEntry {
  final Kala kala; double quantity; double unitPrice; double purchasePrice; double discount;
  OrderItemEntry({required this.kala, this.quantity = 1, required this.unitPrice, this.purchasePrice = 0, this.discount = 0});
  double get totalPrice => quantity * unitPrice - discount;
}
