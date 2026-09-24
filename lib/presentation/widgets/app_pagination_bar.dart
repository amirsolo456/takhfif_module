import 'package:flutter/material.dart';
import '../../shared/utils/iran_format.dart';

/// Customized Persian Pagination & Rows-Per-Page Control Bar for Khatoon Module.
class AppPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;

  const AppPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.pageSize = 20,
    this.pageSizeOptions = const [10, 20, 50, 100],
    this.onPageChanged,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FA);
    final borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            // Page Numbers (PaginationWidget)
            PaginationWidget(
              currentPage: currentPage,
              totalPages: totalPages > 0 ? totalPages : 1,
              onPageChanged: onPageChanged,
            ),

            // Rows Per Page Selector (RowsPerPageWidget)
            RowsPerPageWidget(
              value: pageSize,
              options: pageSizeOptions,
              onChanged: onPageSizeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Persian-style pagination bar displaying page numbers with active page highlight.
class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;
  final int siblingCount;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
    this.siblingCount = 1,
  });

  List<Object> _buildPages() {
    const ellipsis = '...';
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final List<Object> pages = [];
    final int left = (currentPage - siblingCount).clamp(2, totalPages - 1);
    final int right = (currentPage + siblingCount).clamp(2, totalPages - 1);

    pages.add(1);
    if (left > 2) pages.add(ellipsis);
    for (int i = left; i <= right; i++) {
      pages.add(i);
    }
    if (right < totalPages - 1) pages.add(ellipsis);
    pages.add(totalPages);

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final arrowColor = isDark ? Colors.white70 : const Color(0xFF585858);
    final arrowDisabledColor = isDark ? Colors.white24 : const Color(0xFFB1B1B1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          activeColor: arrowColor,
          disabledColor: arrowDisabledColor,
          onTap: () => onPageChanged?.call(currentPage - 1),
        ),
        const SizedBox(width: 4),
        ...pages.map((item) {
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                item,
                style: TextStyle(
                  fontFamily: 'BYekan',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFFB1B1B1),
                ),
              ),
            );
          }
          final page = item as int;
          final isActive = page == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _PageButton(
              page: page,
              isActive: isActive,
              isDark: isDark,
              onTap: () => onPageChanged?.call(page),
            ),
          );
        }),
        const SizedBox(width: 4),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          activeColor: arrowColor,
          disabledColor: arrowDisabledColor,
          onTap: () => onPageChanged?.call(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;

  const _PageButton({
    required this.page,
    required this.isActive,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF383838) : const Color(0xFFECECEC);
    final activeFg = isDark ? Colors.white : const Color(0xFF262626);
    final inactiveFg = isDark ? Colors.white54 : const Color(0xFF888888);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: isActive
            ? BoxDecoration(
                color: activeBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          IranFormat.digits(page),
          style: TextStyle(
            fontFamily: 'BYekan',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color activeColor;
  final Color disabledColor;
  final VoidCallback? onTap;

  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.activeColor,
    required this.disabledColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: enabled ? activeColor : disabledColor,
          ),
        ),
      ),
    );
  }
}

/// Dropdown selector for choosing rows per page count.
class RowsPerPageWidget extends StatefulWidget {
  final int value;
  final List<int> options;
  final ValueChanged<int>? onChanged;

  const RowsPerPageWidget({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
  });

  @override
  State<RowsPerPageWidget> createState() => _RowsPerPageWidgetState();
}

class _RowsPerPageWidgetState extends State<RowsPerPageWidget> {
  bool _isOpen = false;

  void _toggle(BuildContext context) async {
    if (_isOpen) return;
    setState(() => _isOpen = true);

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        0,
      ),
      items: widget.options.map((v) {
        return PopupMenuItem<int>(
          value: v,
          height: 36,
          child: Text(
            IranFormat.digits(v),
            style: TextStyle(
              fontFamily: 'BYekan',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF262626),
            ),
            textDirection: TextDirection.rtl,
          ),
        );
      }).toList(),
      color: isDark ? const Color(0xFF262626) : Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then((selected) {
      setState(() => _isOpen = false);
      if (selected != null) widget.onChanged?.call(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF383838) : const Color(0xFFECECEC);
    final textFg = isDark ? Colors.white : const Color(0xFF262626);

    return InkWell(
      onTap: () => _toggle(context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              IranFormat.digits(widget.value),
              style: TextStyle(
                fontFamily: 'BYekan',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textFg,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isOpen ? 0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 16,
                color: textFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
