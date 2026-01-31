import 'package:flutter/material.dart';

class MatrixTable extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final List<String> criteriaNames;
  final Map<String, String> alternativeNames; // Map ID to Name

  const MatrixTable({
    super.key,
    required this.title,
    required this.data,
    required this.criteriaNames,
    required this.alternativeNames,
  });

  @override
  Widget build(BuildContext context) {
    // If it's a 2D matrix (Alternative ID -> Criterion ID -> Value)
    if (data.isEmpty) return const SizedBox.shrink();

    final firstValue = data.values.first;

    // Check if it's a 2D matrix or a simple 1D map
    if (firstValue is Map<String, dynamic>) {
      return _build2DTable(context);
    } else {
      return _build1DTable(context);
    }
  }

  Widget _build2DTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest,
                ),
                columnSpacing: 24,
                columns: [
                  const DataColumn(
                    label: Text(
                      'Alternative',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...criteriaNames.map(
                    (c) => DataColumn(
                      label: Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                rows: data.entries.map((entry) {
                  final altId = entry.key;
                  final altName = alternativeNames[altId] ?? altId;
                  final values = entry.value as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          altName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ...criteriaNames.map((cId) {
                        final val = values[cId];
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _build1DTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Item',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Value',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: data.entries.map((entry) {
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
        const SizedBox(height: 16),
      ],
    );
  }
}
