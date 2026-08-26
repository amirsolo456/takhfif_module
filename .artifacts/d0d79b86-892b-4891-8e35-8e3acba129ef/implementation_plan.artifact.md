# Implement Create Invoice (ثبت سند) Feature

This plan outlines the steps to implement a comprehensive "Create Invoice" feature across the Android (Flutter) frontend and ASP.NET Core backend, adhering to the existing database schema and project architecture.

## User Review Required

> [!IMPORTANT]
> The backend logic for `IDSal`, `IDSanad`, and `ID2` generation, as well as `AnbarGar` warehouse movement, will be based on the provided SQL schema and deduced from existing stored procedures/services. Any ambiguity in legacy ID generation will be reported.

## Proposed Changes

### Backend (ASP.NET Core)

#### [NEW] [InvoicesController.cs](file:///D:/flutter/khatoon_backend/DamKhatoon.backend/Controllers/InvoicesController.cs)
Implement the `POST /api/invoices` endpoint. It will handle the multi-item, multi-payment invoice creation within a single database transaction.

#### [NEW] [InvoiceCreationService.cs](file:///D:/flutter/khatoon_backend/DamKhatoon.backend/Service/InvoiceCreationService.cs)
A dedicated service to manage the complex logic of creating an invoice:
- Validation (Person, Warehouse, Kala, Stock).
- Legacy ID generation (`IDSal`, `IDSanad`, `ID2`).
- Creating rows in `Invoices`, `InvoicesDetail`, `Payments`, and `PaymentAllocations`.
- Warehouse movement in `AnbarGar`.
- Optional SMS/Coupon generation (post-transaction).

#### [NEW] Models and DTOs
- Create/Update models to match the provided SQL Server schema (`Kala`, `Anbar`, `AnbarGar`, `InvoiceDetail`, etc.).
- `CreateInvoiceRequestDto` and `InvoiceSummaryResponseDto`.

---

### Android (Flutter - invoice_module)

#### [NEW] Request/Response Models
Define `CreateInvoiceRequest`, `InvoiceItemRequest`, `InvoicePaymentRequest` and corresponding response models in `lib/src/features/invoice/data/models/`.

#### [NEW] [InvoiceRepository](file:///D:/flutter/khatoon_modules/invoice_module/lib/src/features/invoice/data/repositories/invoice_repository.dart)
Add `createInvoice` method to the repository to communicate with the new backend endpoint.

#### [NEW] [InvoiceRegistrationPage](file:///D:/flutter/khatoon_modules/invoice_module/lib/src/features/invoice/presentation/pages/invoice_registration_page.dart)
Create a professional UI with the following sections:
- **Buyer:** Search/Select/Create person.
- **Invoice Info:** Warehouse selection, readonly date/user.
- **Products:** Dynamic list for adding multiple items.
- **Payments:** Dynamic list for multiple payment entries.
- **Summary:** Total, Paid, Remaining, Status.
- **Coupon:** Option to send SMS.

---

## Verification Plan

### Automated Tests
- **Backend Unit Tests:** Verify transaction rollback on failure, stock validation, and correct mapping of legacy IDs.
- **Android Unit Tests:** Verify DTO mapping and UI state handling.

### Manual Verification
1. Open the "Create Invoice" screen on the Android emulator.
2. Select a person or create a new one.
3. Select a warehouse.
4. Add multiple products and set quantities/prices.
5. Add multiple payments with different dates.
6. Toggle "Send SMS" and submit.
7. Verify that the invoice is correctly saved in SQL Server (`Invoices`, `InvoicesDetail`, `AnbarGar`, `Payments`, `PaymentAllocations`).
8. Verify that the SMS is "sent" (mocked or real) only after a successful save.
