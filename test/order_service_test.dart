import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:takhfif_module/data/models/order_model.dart';
import 'package:takhfif_module/data/models/order_item_model.dart';
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
      const order = OrderModel(
        firstName: 'امیر',
        lastName: 'باقری',
        mobile: '09123456789',
        items: [
          OrderItemModel(kalaId: '0017', kalaName: 'پشم چین', quantity: 2, unitPrice: 1000, totalPrice: 2000),
        ],
      );

      when(mockOrderRepo.createOrder(any)).thenAnswer((_) async => order);
      when(mockDiscountRepo.insertDiscountCode(any)).thenAnswer((_) async => 1);
      when(mockDiscountRepo.getSetting('sms_api_key')).thenAnswer((_) async => null);
      when(mockDiscountRepo.getSetting('sms_mock_mode')).thenAnswer((_) async => 'true');
      when(mockDiscountRepo.getSetting('sms_sender')).thenAnswer((_) async => null);
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

      await orderService.placeOrder(order, sendDiscountSms: true);

      verify(mockOrderRepo.createOrder(any)).called(1);
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
