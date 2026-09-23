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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF585858),
                    ),
                  )
                : const CustomRefreshIcon(
                    size: 20,
                    color: Color(0xFF585858),
                  ),
          ),
        ),
      ),
    );
  }
}
