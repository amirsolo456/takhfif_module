import 'package:flutter/material.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final double size;

  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = value
        ? (isDark ? const Color(0xFF2563EB) : Colors.black)
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDEDED));

    final Color borderColor = value
        ? (isDark ? const Color(0xFF2563EB) : Colors.black)
        : (isDark ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: value
            ? Icon(
                Icons.check_rounded,
                size: size * 0.72,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

class AppCheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final bool enabled;

  const AppCheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppCheckbox(
              value: value,
              onChanged: enabled && onChanged != null ? (val) => onChanged!(val) : null,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'BYekan',
                fontFamilyFallback: ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.8,
                color: Color(0xFF585858),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
