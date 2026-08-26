import '../../core/utils/discount_code_generator.dart';
import '../../data/models/discount_code.dart';
import '../../data/models/order.dart';
import '../../data/repositories/discount_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../infrastructure/external_services/sms_service.dart';

class OrderService {
  final OrderRepository _orderRepository;
  final DiscountRepository _discountRepository;
  final SmsService? _smsService;

  OrderService({
    OrderRepository? orderRepository,
    DiscountRepository? discountRepository,
    SmsService? smsService,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _discountRepository = discountRepository ?? DiscountRepository(),
        _smsService = smsService;

  Future<void> placeOrder(Order order, {bool sendDiscountSms = false}) async {
    // 1. ثبت سفارش (سند) در دیتابیس
    await _orderRepository.insertOrder(order);

    if (sendDiscountSms) {
      // 2. تولید کد تخفیف ارسال رایگان برای خرید بعدی
      final String phoneSuffix = order.customerPhone.length >= 4 
          ? order.customerPhone.substring(order.customerPhone.length - 4) 
          : order.customerPhone;
      
      final String generatedCode = "FREE-$phoneSuffix-${DiscountCodeGenerator.generate(length: 4)}";

      final discountCode = DiscountCode(
        code: generatedCode,
        discountType: DiscountType.freeShipping,
        discountValue: 0,
        startDate: DateTime.now(),
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        usageLimit: 1,
        remainingUsage: 1,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _discountRepository.insertDiscountCode(discountCode);

      // 3. ارسال اس ام اس تبریک و کد تخفیف
      final apiKey = await _discountRepository.getSetting('sms_api_key');
      final mockModeStr = await _discountRepository.getSetting('sms_mock_mode');
      final sender = await _discountRepository.getSetting('sms_sender');
      final isMock = mockModeStr == 'true' || mockModeStr == null;

      final smsService = _smsService ?? KavenegarSmsService(
        apiKey: apiKey ?? 'YOUR_KAVENEGAR_API_KEY',
        useMock: isMock,
      );

      final String message = "سلام ${order.customerName} عزیز،\n"
          "سفارش شما با موفقیت ثبت شد.\n"
          "محصولات:\n${order.productsSummary}\n"
          "تبریک! برای خرید بعدی شما یک کد تخفیف «ارسال رایگان» در نظر گرفته شده است:\n"
          "کد: $generatedCode\n"
          "شناسه شما: ${order.customerPhone}";

      await smsService.sendDirectSms(
        phone: order.customerPhone,
        message: message,
        sender: sender,
      );
    }
  }

  Future<List<Order>> getAllOrders() => _orderRepository.getAllOrders();
}
