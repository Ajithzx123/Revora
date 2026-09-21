import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            emptyMessage,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => cardBuilder!(items[index]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.primarySubtle),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
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
