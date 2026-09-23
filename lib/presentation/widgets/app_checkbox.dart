import 'package:flutter/material.dart';

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
          crossAxisAlignment: CrossAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: value ? const Color(0xFF6B6B6B) : const Color(0xFF939393),
                  width: value ? 0.5 : 1.0,
                ),
                activeColor: const Color(0xFFECECEC),
                checkColor: const Color(0xFF585858),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IRANSansFaNum',
                fontFamilyFallback: ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.8, // 180% (22px line height)
                color: Color(0xFF585858),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
