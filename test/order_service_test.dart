import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:takhfif_module/data/models/order.dart';
import 'package:takhfif_module/data/repositories/order_repository.dart';
import 'package:takhfif_module/data/repositories/discount_repository.dart';
import 'package:takhfif_module/domain/services/order_service.dart'
    show OrderService;
import 'package:takhfif_module/infrastructure/external_services/sms_service.dart';

@GenerateMocks([OrderRepository, DiscountRepository, SmsService])
import 'order_service_test.mocks.dart';

void main() {
  late MockOrderRepository mockOrderRepo;
  late MockDiscountRepository mockDiscountRepo;
  late MockSmsService mockSmsService;
  late OrderService orderService;

  setUp(() {
    mockOrderRepo = MockOrderRepository();
    mockDiscountRepo = MockDiscountRepository();
    mockSmsService = MockSmsService();
    orderService = OrderService(
      orderRepository: mockOrderRepo,
      discountRepository: mockDiscountRepo,
      smsService: mockSmsService,
    );
  });

  test(
    'placeOrder should save order, generate discount and send SMS',
    () async {
      final order = Order(
        customerName: 'امیر',
        customerAddress: 'تهران، خیابان آزادی',
        customerPhone: '09123456789',
        items: [
          OrderItem(productName: 'تیشرت', quantity: 2),
          OrderItem(productName: 'کلاه', quantity: 1),
        ],
        createdAt: DateTime.now(),
        payments: [],
      );

      when(mockOrderRepo.insertOrder(any)).thenAnswer((_) async => 1);
      when(mockDiscountRepo.insertDiscountCode(any)).thenAnswer((_) async => 1);
      when(
        mockSmsService.sendDirectSms(
          phone: anyNamed('phone'),
          message: anyNamed('message'),
          sender: anyNamed('sender'),
        ),
      ).thenAnswer(
        (_) async => SmsResponse(
          success: true,
          statusCode: 200,
          message: 'OK',
          rawBody: '',
        ),
      );

      await orderService.placeOrder(order);

      verify(mockOrderRepo.insertOrder(any)).called(1);
      verify(mockDiscountRepo.insertDiscountCode(any)).called(1);
      verify(
        mockSmsService.sendDirectSms(
          phone: anyNamed('phone'),
          message: anyNamed('message'),
          sender: anyNamed('sender'),
        ),
      ).called(1);
    },
  );
}
