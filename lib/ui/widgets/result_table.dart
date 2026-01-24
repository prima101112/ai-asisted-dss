import 'package:flutter/material.dart';
import '../../models/decision_session.dart';

class ResultTable extends StatelessWidget {
  final List<RankingResult> results;

  const ResultTable({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primary.withAlpha(30),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Rank',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Alternative',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Score',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: results.map((res) {
            final isFirst = res.rank == 1;
            final colorScheme = Theme.of(context).colorScheme;
            return DataRow(
              cells: [
                DataCell(
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isFirst
                        ? colorScheme.secondary
                        : colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${res.rank}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isFirst
                            ? colorScheme.onSecondary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    res.alternativeName,
                    style: TextStyle(
                      fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(Text(res.score.toStringAsFixed(3))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
