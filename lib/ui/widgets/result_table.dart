import 'package:flutter/material.dart';
import '../../models/decision_session.dart';
import '../../l10n/app_localizations.dart';

class ResultTable extends StatelessWidget {
  final List<RankingResult> results;

  const ResultTable({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      l10n.translate('rank'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.translate('alternative'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      l10n.translate('score'),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Data rows
            ...results.map((res) => _buildResultRow(context, res)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, RankingResult res) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTop3 = res.rank <= 3;
    
    // Medal colors aligned with history detail screen
    Color? medalColor;
    if (res.rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
    } else if (res.rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
    } else if (res.rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withAlpha(30),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank circle - aligned with history detail design
          SizedBox(
            width: 50,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: isTop3 && medalColor != null
                  ? medalColor.withAlpha(40)
                  : colorScheme.surfaceContainerHighest,
              child: Text(
                '${res.rank}',
                style: TextStyle(
                  fontSize: 12,
                  color: isTop3 && medalColor != null
                      ? medalColor
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Alternative name with flexible space
          Expanded(
            child: Text(
              res.alternativeName,
              style: TextStyle(
                fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Score - fixed width, right aligned
          SizedBox(
            width: 70,
            child: Text(
              res.score.toStringAsFixed(3),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isTop3 && medalColor != null
                    ? medalColor
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
