import 'package:flutter/material.dart';
import 'package:revora/core/theme/app_spacing.dart';

class ResponsiveDataTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> items;
  final List<Widget> Function(T item) rowBuilder;
  final Widget Function(T item)? cardBuilder;
  final void Function(T item)? onRowTap;
  final String emptyMessage;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    this.cardBuilder,
    this.onRowTap,
    this.emptyMessage = 'No records found',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final isNarrow = MediaQuery.of(context).size.width < 700;

    if (isNarrow && cardBuilder != null) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => cardBuilder!(items[index]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outline, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              cs.primary.withValues(alpha: 0.08),
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: cs.onSurface,
            ),
            dataTextStyle: TextStyle(
              fontSize: 13,
              color: cs.onSurface,
            ),
            columnSpacing: AppSpacing.xxl,
            horizontalMargin: AppSpacing.lg,
            columns: columns
                .map((col) => DataColumn(label: Text(col)))
                .toList(),
            rows: items.map((item) {
              final cells = rowBuilder(item);
              return DataRow(
                onSelectChanged: onRowTap != null ? (_) => onRowTap!(item) : null,
                cells: cells.map((cell) => DataCell(cell)).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
