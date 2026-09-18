import 'package:flutter/material.dart';

class DocumentSummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const DocumentSummaryCard({
    super.key,
    required this.title,
    this.icon = Icons.receipt_long_rounded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: .35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: .25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
