import 'package:flutter/material.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final bool isOn = value;

    return GestureDetector(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      child: Container(
        width: 47,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCECECE), width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: isOn
              ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
              : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? const Color(0xFF0E0E0E) : const Color(0xFFCECECE),
            ),
          ),
        ),
      ),
    );
  }
}
