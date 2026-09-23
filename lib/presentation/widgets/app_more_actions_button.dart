import 'package:flutter/material.dart';

class AppMoreActionsButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;

  const AppMoreActionsButton({
    super.key,
    this.onPressed,
    this.tooltip = 'عملیات‌های بیشتر',
    this.icon = Icons.more_vert_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFFF4F4F4) : const Color(0xFF585858);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
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
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class AppMoreActionsPopupMenuButton<T> extends StatelessWidget {
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final String tooltip;

  const AppMoreActionsPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.tooltip = 'عملیات‌های بیشتر',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFFF4F4F4) : const Color(0xFF585858);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        borderRadius: BorderRadius.circular(8),
        icon: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: iconColor,
          ),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
    );
  }
}
