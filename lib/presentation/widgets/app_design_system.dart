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

String _extractTextFromWidget(Widget? widget) {
  if (widget == null) return '';
  if (widget is Text) {
    return widget.data ?? '';
  }
  if (widget is Row) {
    return widget.children.map(_extractTextFromWidget).join(' ');
  }
  if (widget is Column) {
    return widget.children.map(_extractTextFromWidget).join(' ');
  }
  if (widget is Flexible) {
    return _extractTextFromWidget(widget.child);
  }
  if (widget is Expanded) {
    return _extractTextFromWidget(widget.child);
  }
  if (widget is Container) {
    return _extractTextFromWidget(widget.child);
  }
  if (widget is Padding) {
    return _extractTextFromWidget(widget.child);
  }
  if (widget is PopupMenuItem) {
    return _extractTextFromWidget(widget.child);
  }
  return '';
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

  void _showSearchableMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (ctx) {
        return _SearchablePopupMenuDialog<T>(
          position: position,
          items: items,
          onSelected: onSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF515151) : const Color(0xFFF4F4F4);
    final textFg = isDark ? Colors.white : const Color(0xFF262626);

    // Count selectable/interactive items (excluding dividers)
    final itemCount = items.where((e) => e is! PopupMenuDivider).length;
    final bool needsSearch = itemCount > 5;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: needsSearch
          ? InkWell(
              onTap: () => _showSearchableMenu(context),
              borderRadius: BorderRadius.circular(6),
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
            )
          : PopupMenuButton<T>(
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

class _SearchablePopupMenuDialog<T> extends StatefulWidget {
  final RelativeRect position;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T>? onSelected;

  const _SearchablePopupMenuDialog({
    required this.position,
    required this.items,
    this.onSelected,
  });

  @override
  State<_SearchablePopupMenuDialog<T>> createState() => _SearchablePopupMenuDialogState<T>();
}

class _SearchablePopupMenuDialogState<T> extends State<_SearchablePopupMenuDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _normalize(String input) {
    var text = input.trim().toLowerCase();
    text = text.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const en = '0123456789';
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(fa[i], en[i]);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _normalize(_searchQuery);

    final filteredItems = widget.items.where((entry) {
      if (entry is PopupMenuDivider) return _searchQuery.isEmpty;
      final text = _normalize(_extractTextFromWidget(entry));
      if (query.isEmpty) return true;
      return text.contains(query);
    }).toList();

    return Stack(
      children: [
        Positioned(
          top: widget.position.top + 4,
          right: widget.position.right > 0 ? widget.position.right : 12,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              elevation: 8,
              color: isDark ? const Color(0xFF262626) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black26,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar at Top (دقیقاً طبق عکس کاربر)
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF383838) : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'جستجو کنید',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          suffixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Scrollable Filtered List below Search Bar
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filteredItems.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          'موردی یافت نشد',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ]
                                : filteredItems.map((entry) {
                                    if (entry is PopupMenuDivider) {
                                      return const Divider(height: 8);
                                    }
                                    if (entry is PopupMenuItem<T>) {
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: entry.enabled
                                            ? () {
                                                Navigator.pop(context);
                                                if (widget.onSelected != null && entry.value != null) {
                                                  widget.onSelected!(entry.value as T);
                                                }
                                              }
                                            : null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          child: Opacity(
                                            opacity: entry.enabled ? 1.0 : 0.5,
                                            child: entry.child,
                                          ),
                                        ),
                                      );
                                    }
                                    return entry;
                                  }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
