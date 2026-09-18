import 'package:flutter/material.dart';
import '../../data/models/person.dart';

class PersonSelectionCard extends StatelessWidget {
  final Person? selectedPerson;
  final VoidCallback onSelect;
  final VoidCallback? onCreateNew;
  final String placeholderTitle;
  final String placeholderSubtitle;

  const PersonSelectionCard({
    super.key,
    required this.selectedPerson,
    required this.onSelect,
    this.onCreateNew,
    this.placeholderTitle = 'طرف حساب انتخاب نشده است',
    this.placeholderSubtitle = 'برای ثبت فاکتور، طرف حساب را انتخاب کنید.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPerson = selectedPerson != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .6),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasPerson
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasPerson ? Icons.person_rounded : Icons.person_search_rounded,
                color: hasPerson
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPerson ? selectedPerson!.fullName : placeholderTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasPerson
                        ? (selectedPerson!.mobile ?? 'بدون شماره همراه')
                        : placeholderSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCreateNew != null) ...[
                  IconButton.filledTonal(
                    tooltip: 'تعریف مشتری جدید',
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    padding: EdgeInsets.zero,
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.person_add_rounded, size: 19),
                  ),
                  const SizedBox(width: 6),
                ],
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onSelect,
                  icon: Icon(
                    hasPerson ? Icons.edit_rounded : Icons.search_rounded,
                    size: 17,
                  ),
                  label: Text(
                    hasPerson ? 'تغییر' : 'انتخاب',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
