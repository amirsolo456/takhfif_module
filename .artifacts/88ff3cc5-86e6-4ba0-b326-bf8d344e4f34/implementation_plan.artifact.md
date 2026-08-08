# Implementation Plan - Fix Errors and Redesign Windows UI

The user wants to fix all project errors and redesign the Windows Home Page. The new design should feature two main panels for "Issue" and "Consume" with a tab system at the top for navigating to histories.

## User Review Required

> [!IMPORTANT]
> The redesign involves changing the layout from a side-by-side Split View to a **Tabbed View**. This will significantly change how the user interacts with the app on Desktop.
>
> **Proposed Tab Structure:**
> 1. **عملیات اصلی (Main Operations)**: Contains the "Issue Discount" and "Consume Discount" panels side-by-side.
> 2. **کدهای صادر شده (Issued Codes)**: The full table of discount codes.
> 3. **سابقه مصرف (Usage History)**: The full table of usage logs.

## Proposed Changes

### Core Logic & Fixes (From previous request)
- Fix database initialization in `DiscountController`, `DiscountService`, and `DiscountRepository`.
- Correct `FilePicker` API usage in `DiscountController`.
- Fix `DropdownButtonFormField` parameter `initialValue` -> `value` in panels.

### Windows UI Redesign

#### [MODIFY] [windows_discount_home_page.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/pages/windows_discount_home_page.dart)
- Implement `DefaultTabController` with 3 tabs.
- Update `AppBar` to include a `TabBar` in the `bottom` property.
- Replace the current `Row` layout with a `TabBarView`.
- Create a new layout for the "Operations" tab where `WindowsCreateDiscountPanel` and `WindowsConsumeDiscountPanel` are displayed as large cards side-by-side or in a centered layout.

#### [MODIFY] [windows_create_discount_panel.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_create_discount_panel.dart)
- Wrap the content in a `Card` to make it stand out as a standalone panel if it isn't already (currently it's just a `Column`).
- Adjust padding and constraints for the new centered layout.

#### [MODIFY] [windows_consume_discount_panel.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_consume_discount_panel.dart)
- Wrap the content in a `Card`.
- Adjust padding and constraints.

---

### UI Polish
- Ensure the Persian fonts (Tahoma/IRANSans) are consistent if possible.
- Add better visual separation between sections in the Operations tab.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no static errors.
- Run `flutter test`.

### Manual Verification
- Verify the new Tab system works correctly.
- Ensure the "Issue" and "Consume" cards look good on large screens.
- Test the database persistence (CRUD operations) through the new UI.
