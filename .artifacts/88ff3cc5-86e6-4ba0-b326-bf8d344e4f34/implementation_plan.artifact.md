# Implementation Plan - Fix SMS Delivery Visibility & Error Handling

The user reports that a "Success" message is shown but no SMS is delivered. This is likely because the current service catches and swallows exceptions, preventing the UI from knowing the operation actually failed.

## User Review Required

> [!IMPORTANT]
> **Why it was failing silently**: The previous code caught network/API errors and only `debugPrint`ed them. I will change this so errors are **rethrown**. This will cause the UI to show the actual error message (e.g., "Invalid API Key" or "No Credit") instead of a fake success message.

## Proposed Changes

### 1. Infrastructure Layer

#### [MODIFY] [sms_service.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/infrastructure/external_services/sms_service.dart)
- Remove the `try-catch` blocks that swallow errors in `sendDirectSms`, `sendConsumptionNotification`, and `sendLookupNotification`.
- Ensure `rethrow` or just let the exception bubble up.

---

### 2. Domain Layer

#### [MODIFY] [discount_service.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/domain/services/discount_service.dart)
- Ensure exceptions from `smsService` are not caught here unless they are handled.

---

### 3. State Management

#### [MODIFY] [discount_controller.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/shared/controllers/discount_controller.dart)
- Ensure `sendDirectSms` doesn't swallow errors.

---

### 4. UI Layer

#### [MODIFY] [windows_sms_draft_dialog.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_sms_draft_dialog.dart)
- The existing `try-catch` will now actually catch the errors thrown by the service.
- The error snackbar will display the **actual reason** for failure (e.g., "Kavenegar Error: اعتبار کافی نیست").

---

## Verification Plan

### Manual Verification
1. Open the app.
2. Ensure **Mock Mode** is **OFF**.
3. Try to send a test SMS or a draft SMS.
4. If there is an issue (Invalid Key, No Credit, etc.), verify that a **Red Snackbar** with the error message appears instead of a green success one.
5. If it works, verify the message is received on the phone.
