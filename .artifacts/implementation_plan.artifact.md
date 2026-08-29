# Implementation Plan - Discount Module Integration with Backend

Align the Flutter project's Order and Discount logic with the existing .NET Backend. Since the backend integrates discounts directly into `OrderItems`, we will implement models and services that reflect this structure.

## User Review Required

> [!IMPORTANT]
> The existing `Order` and `OrderItem` models in `lib/data/models/order.dart` appear to be designed for local storage (SQLite) with different fields (e.g., `customerName` instead of `personId`). I will create new API-specific models to avoid breaking existing local functionality, following the naming convention `order_model.dart` and `order_item_model.dart` as suggested.

## Proposed Changes

### Data Layer (Models & Requests)

#### [NEW] [order_item_model.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/order_item_model.dart)
Create `OrderItemModel` to match `OrderItemDto`.
- Fields: `id`, `kalaId`, `quantity`, `unitPrice`, `discount`, `totalPrice`.
- Logic: Include a getter for `calculatedTotalPrice` to show local preview before sending to backend.

#### [NEW] [order_model.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/order_model.dart)
Create `OrderModel` to match `OrderDto`.
- Fields: `id`, `personId`, `orderDate`, `status`, `totalAmount`, `description`, `items`.

#### [NEW] [create_order_request.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/create_order_request.dart)
Create `CreateOrderRequest` and `CreateOrderItemRequest` to match backend input DTOs.
- This will be used for `POST /api/orders`.

---

### Data Layer (Repositories)

#### [NEW] [order_api_repository.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/repositories/order_api_repository.dart)
Implement the API repository for orders.
- Method: `Future<OrderModel> getOrder(int id)`
- Method: `Future<OrderModel> createOrder(CreateOrderRequest request)`
- Uses `http` package, consistent with `invoice_api_repository.dart`.

---

### Domain Layer (Services)

#### [NEW] [order_api_service.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/domain/services/order_api_service.dart)
Implement a service to orchestrate order operations.
- Provides a clean interface for the UI.
- Handles potential errors (consistent with the project's error handling style).

---

## Verification Plan

### Automated Tests
- I will run `flutter analyze` to ensure no syntax errors or type mismatches.

### Manual Verification
- Check that `totalPrice` in `OrderItemModel` correctly calculates `(quantity * unitPrice) - discount`.
- Verify JSON serialization keys match the backend exactly (CamelCase).
