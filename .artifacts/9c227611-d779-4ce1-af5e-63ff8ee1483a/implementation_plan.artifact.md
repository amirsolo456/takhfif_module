# Implement Create Invoice (ثبت سند) Feature

This plan covers the implementation of a full "Create Invoice" feature, including the backend logic in C# (ASP.NET Core) and the frontend UI in Flutter.

## User Review Required

> [!IMPORTANT]
> - The backend logic for `IDSal`, `IDSanad`, and `ID2` generation, as well as `AnbarGar` warehouse movement, follows the legacy patterns found in the existing `InvoiceCreationService` and `DirectDatabaseService`.
> - SMS sending will be implemented using a post-transaction workflow as requested.
> - The frontend will be implemented in Flutter (using Provider/ChangeNotifier) as per the project's current structure.

## Proposed Changes

### Backend (C# - DamKhatoon.backend)

#### [MODIFY] [InvoiceCreationService.cs](file:///D:/flutter/khatoon_backend/DamKhatoon.backend/Service/InvoiceCreationService.cs)
- Refine the existing service to ensure strict validation of stock and prices.
- Implement post-transaction Coupon generation in the `Takhfif` table.
- Implement post-transaction SMS sending logic (reading config from `InfAdv`).
- Ensure all totals (`MabFrosh`, `MabNaghd`, etc.) are calculated and saved in the `Invoices` table header.

#### [MODIFY] [InvoiceController.cs](file:///D:/flutter/khatoon_backend/DamKhatoon.backend/Controllers/InvoiceController.cs)
- Replace or add a `POST /api/invoices` endpoint that uses `IInvoiceCreationService`.
- Use `User.Identity` to get the `currentUserId` for the `ChangeUser` field.

#### [NEW] [SmsService.cs](file:///D:/flutter/khatoon_backend/DamKhatoon.backend/Service/SmsService.cs)
- Create a backend SMS service to handle post-transaction notifications.

---

### Frontend (Flutter - takhfif_module)

#### [NEW] [InvoiceRegistrationRequest](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/models/invoice_registration.dart)
Define data models for the invoice registration request and response.

#### [NEW] [InvoiceRepository](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/repositories/invoice_api_repository.dart)
Implement an API-based repository for invoice registration using the `http` package.

#### [NEW] [InvoiceRegistrationController](file:///D:/flutter/khatoon_modules/takhfif_module/lib/shared/controllers/invoice_registration_controller.dart)
A `ChangeNotifier` to manage the state of the invoice registration form (loading, validation, success/error).

#### [NEW] [InvoiceRegistrationPage](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/pages/invoice_registration_page.dart)
A comprehensive UI with sections:
- **Buyer:** Search/Select/Create person (integrating with `PersonsController` endpoints).
- **Invoice Header:** Warehouse selection (dropdown from `Anbar` table), read-only date/user.
- **Products:** Dynamic list with Add/Remove buttons.
- **Payments:** Dynamic list for multiple payments.
- **Summary:** Total, Paid, Remaining, Status.
- **SMS Checkbox:** Option to send discount SMS.
- **Submit Button:** "ثبت سند" with loading indicator.

---

## Verification Plan

### Automated Tests
- **Backend:** Verify that `InvoiceCreationService` correctly rolls back if stock is insufficient or payment validation fails.
- **Frontend:** Verify that the UI correctly calculates line totals and prevents submission with invalid data.

### Manual Verification
1. Open the "Create Invoice" screen.
2. Search and select an existing person.
3. Select a warehouse.
4. Add multiple products, verify line totals.
5. Add multiple payments.
6. Check "Send SMS" and click "ثبت سند".
7. Verify in SQL Server:
    - New row in `Invoices` and multiple rows in `InvoicesDetail`.
    - `AnbarGar` mojodi/tafazol decreased correctly.
    - Rows in `Payments` and `PaymentAllocations` created.
    - Row in `Takhfif` created (if SMS enabled).
    - SMS logged/sent.
