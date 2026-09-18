import 'package:flutter/material.dart';

class StickyBottomActionBar extends StatelessWidget {
  final Widget child;

  const StickyBottomActionBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? .25 : .06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: child,
        ),
      ),
    );
  }
}
