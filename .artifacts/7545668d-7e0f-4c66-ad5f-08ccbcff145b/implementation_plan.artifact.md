# Implementation Plan - Fix all remaining errors

Fix return types, undefined identifiers, and broken imports across the project.

## User Review Required

> [!IMPORTANT]
> I will be updating imports in multiple presentation files to correctly reference core, data, and shared modules.

## Proposed Changes

### Data Layer

#### [MODIFY] [discount_repository.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/data/repositories/discount_repository.dart)
- Fix `consumeDiscountCode` to return `true` at the end of the transaction.
- Use the `db` variable (which handles the transaction context) instead of `_db` inside the transaction.
- Remove the unused `db` warning by correctly using it.

### Core Layer

#### [MODIFY] [platform_helper.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/core/utils/platform_helper.dart)
- (Already verified) Ensure all platform getters are present.

### Presentation Layer

#### [MODIFY] Multiple files in `lib/presentation/`
I will fix the imports in the following files:
- [mobile_discount_codes_page.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/android/pages/mobile_discount_codes_page.dart)
- [mobile_discount_history_page.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/android/pages/mobile_discount_history_page.dart)
- [mobile_discount_home_page.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/android/pages/mobile_discount_home_page.dart)
- [mobile_consume_discount_card.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/android/widgets/mobile_consume_discount_card.dart)
- [mobile_create_discount_card.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/android/widgets/mobile_create_discount_card.dart)
- [windows_discount_home_page.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/pages/windows_discount_home_page.dart)
- [windows_consume_discount_panel.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_consume_discount_panel.dart)
- [windows_create_discount_panel.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_create_discount_panel.dart)
- [windows_discount_table.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_discount_table.dart)
- [windows_usage_table.dart](file:///D:/flutter/khatoon_modules/takhfif_module/lib/presentation/windows/widgets/windows_usage_table.dart)

The fix involves updating relative imports from `../../` to `../../../` to correctly reach the `lib/` root folders, or switching to package imports.

## Verification Plan

### Manual Verification
- Verify that all files compile without errors in the IDE.
