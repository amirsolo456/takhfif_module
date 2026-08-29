# Implementation Plan - Flutter Order Management

This plan outlines the steps to implement the Order Management system in Flutter, following the architecture and models proposed by the user.

## User Review Required

> [!IMPORTANT]
> The proposed models `OrderModel` and `OrderItemModel` differ significantly from the existing ones in `lib/data/models/`. I will update the existing files to match your proposal, as it seems you want to refactor the order system.

## Proposed Changes

### Data Layer

#### [MODIFY] [order_item_model.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/order_item_model.dart)
- Update to include `kalaId` (String), `kalaName`, `quantity`, `unitPrice`, and `totalPrice`.

#### [MODIFY] [order_model.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/order_model.dart)
- Update to include `firstName`, `lastName`, `mobile`, `address`, `paymentDate`, `paymentAmount`, `status`, `tarafId`, `sanadId`, and `items`.

#### [NEW] [customer_model.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/customer_model.dart)
- Create a basic customer model if needed (placeholder for now).

#### [NEW] [product_model.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/product_model.dart)
- Create a basic product model if needed (placeholder for now).

#### [NEW] [order_repository.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/repositories/order_repository.dart)
- Implement `OrderRepository` interface and its Dio-based implementation.

### Presentation Layer

#### [NEW] [order_controller.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/controllers/order_controller.dart)
- Implement `OrderController` using GetX for state management.

#### [NEW] [create_order_page.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/pages/create_order_page.dart)
- Implement the "ثبت سفارش" (Create Order) page with the form fields and product selection.

## Verification Plan

### Automated Tests
- Unit tests for `OrderModel` and `OrderItemModel` serialization.

### Manual Verification
- Verify the UI layout and form validation in the Flutter app.
- Check if the "ثبت سفارش" button triggers the correct repository call.
