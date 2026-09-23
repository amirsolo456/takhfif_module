import 'package:flutter/material.dart';
import 'custom_refresh_icon.dart';

class AppRefreshButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String tooltip;

  const AppRefreshButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.tooltip = 'بروزرسانی',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF515151) : const Color(0xFFF4F4F4);
    final iconColor = isDark ? const Color(0xFFF4F4F4) : const Color(0xFF585858);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: iconColor,
                    ),
                  )
                : CustomRefreshIcon(
                    size: 20,
                    color: iconColor,
                  ),
          ),
        ),
      ),
    );
  }
}
