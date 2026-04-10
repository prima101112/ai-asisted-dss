import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class MatrixTable extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  final List<String> criterionIds;
  final Map<String, String> criterionLabels;
  final Map<String, String> alternativeNames; // Map ID to Name

  const MatrixTable({
    super.key,
    required this.title,
    required this.data,
    required this.criterionIds,
    required this.criterionLabels,
    required this.alternativeNames,
  });

  @override
  State<MatrixTable> createState() => _MatrixTableState();
}

class _MatrixTableState extends State<MatrixTable> {
  bool _isExpanded = false;
  static const int _initialItemCount = 5;

  @override
  Widget build(BuildContext context) {
    // If it's a 2D matrix (Alternative ID -> Criterion ID -> Value)
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final firstValue = widget.data.values.first;

    // Check if it's a 2D matrix or a simple 1D map
    if (firstValue is Map<String, dynamic>) {
      return _build2DTable(context);
    } else {
      return _build1DTable(context);
    }
  }

  Widget _build2DTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final entries = widget.data.entries.toList();
    final columnIds = _resolveColumnIds(entries);
    final rowHeaderLabel = _resolveRowHeaderLabel(entries, columnIds);
    final itemCount = entries.length;
    final showExpandButton = itemCount > _initialItemCount;
    final displayedEntries = (_isExpanded || !showExpandButton)
        ? entries
        : entries.take(_initialItemCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest.withAlpha(128),
                ),
                columnSpacing: 24,
                horizontalMargin: 16,
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                columns: [
                  DataColumn(label: Text(rowHeaderLabel)),
                  ...columnIds.map(
                    (columnId) =>
                        DataColumn(label: Text(_labelForId(columnId))),
                  ),
                ],
                rows: displayedEntries.map((entry) {
                  final rowId = entry.key;
                  final rowLabel = _labelForId(rowId);
                  final values = entry.value as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          rowLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ...columnIds.map((columnId) {
                        final val = values[columnId];
                        return DataCell(
                          Text(
                            val is double
                                ? val.toStringAsFixed(3)
                                : val.toString(),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        // Expand/Collapse Button
        if (showExpandButton)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
              ),
              label: Text(
                _isExpanded
                    ? l10n.translate('showLess')
                    : l10n
                          .translate('showMore')
                          .replaceAll(
                            '{count}',
                            '${itemCount - _initialItemCount}',
                          ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<String> _resolveColumnIds(List<MapEntry<String, dynamic>> entries) {
    final firstRow = entries.first.value;
    if (firstRow is! Map<String, dynamic>) {
      return widget.criterionIds;
    }

    final rowColumnIds = firstRow.keys.toList();
    final preferredIds = widget.criterionIds;
    final matchesPreferredIds =
        preferredIds.isNotEmpty &&
        preferredIds.every((criterionId) => rowColumnIds.contains(criterionId));

    return matchesPreferredIds ? preferredIds : rowColumnIds;
  }

  String _resolveRowHeaderLabel(
    List<MapEntry<String, dynamic>> entries,
    List<String> columnIds,
  ) {
    final rowIds = entries.map((entry) => entry.key).toList();
    final allRowsAreAlternatives = rowIds.every(
      widget.alternativeNames.containsKey,
    );
    final allColumnsAreAlternatives = columnIds.every(
      widget.alternativeNames.containsKey,
    );

    if (allRowsAreAlternatives && allColumnsAreAlternatives) {
      return 'Alternative';
    }

    return 'Item';
  }

  String _labelForId(String id) {
    return widget.criterionLabels[id] ?? widget.alternativeNames[id] ?? id;
  }

  Widget _build1DTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final entries = widget.data.entries.toList();
    final itemCount = entries.length;
    final showExpandButton = itemCount > _initialItemCount;
    final displayedEntries = (_isExpanded || !showExpandButton)
        ? entries
        : entries.take(_initialItemCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest.withAlpha(128),
              ),
              horizontalMargin: 16,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Value')),
              ],
              rows: displayedEntries.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(entry.key)),
                    DataCell(
                      Text(
                        entry.value is double
                            ? (entry.value as double).toStringAsFixed(3)
                            : entry.value.toString(),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        // Expand/Collapse Button
        if (showExpandButton)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
              ),
              label: Text(
                _isExpanded
                    ? l10n.translate('showLess')
                    : l10n
                          .translate('showMore')
                          .replaceAll(
                            '{count}',
                            '${itemCount - _initialItemCount}',
                          ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
