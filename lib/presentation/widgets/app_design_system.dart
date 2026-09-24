import 'package:flutter/material.dart';

/// Primary Dark Action Button (e.g., "+ ثبت صندوق جدید", "+ افزودن شاخه اصلی")
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E0E0E),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'BYekan',
                  fontFamilyFallback: ['BYekan', 'Tahoma'],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary Outlined/White Action Button (e.g., "+ ثبت صندوق جدید" in white style)
class AppSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final border = isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
    final textFg = isDark ? Colors.white : const Color(0xFF18181B);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textFg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'BYekan',
                  fontFamilyFallback: const ['BYekan', 'Tahoma'],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action Dropdown Button (e.g., "لیست اصلی v", "عملیات گروهی v", "فرم اصلی v")
class AppDropdownButton<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T>? onSelected;

  const AppDropdownButton({
    super.key,
    required this.title,
    required this.items,
    this.value,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF515151) : const Color(0xFFF4F4F4);
    final textFg = isDark ? Colors.white : const Color(0xFF262626);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (ctx) => items,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'BYekan',
                  fontFamilyFallback: const ['BYekan', 'Tahoma'],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Split Save Button with Dropdown ("ذخیره v")
class AppSaveSplitButton extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onOptionPressed;
  final String label;

  const AppSaveSplitButton({
    super.key,
    required this.onSave,
    this.onOptionPressed,
    this.label = 'ذخیره',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E0E0E),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onOptionPressed ?? onSave,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
            ),
          ),
          Container(width: 0.5, height: 18, color: Colors.white24),
          InkWell(
            onTap: onSave,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'BYekan',
                  fontFamilyFallback: ['BYekan', 'Tahoma'],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square 34x34px Icon Button (e.g., Refresh, Close, Print, Add, Fullscreen, Help, Navigation)
class AppSquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isDarkVariant;

  const AppSquareIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isDarkVariant = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final useDark = isDarkVariant || isDarkTheme;

    final bg = useDark ? const Color(0xFF515151) : const Color(0xFFF4F4F4);
    final fg = useDark ? Colors.white : const Color(0xFF585858);

    final buttonWidget = Material(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: fg,
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: buttonWidget);
    }
    return buttonWidget;
  }
}

/// Soft Action Chip Button (e.g., "بازکردن همه", "بستن همه")
class AppActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppActionChip({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF383838) : const Color(0xFFF4F4F4);
    final fg = isDark ? Colors.white70 : const Color(0xFF333333);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'BYekan',
              fontFamilyFallback: const ['BYekan', 'Tahoma'],
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
