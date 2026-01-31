import 'package:flutter/material.dart';
import '../../models/decision_session.dart';
import '../../l10n/app_localizations.dart';

class ResultTable extends StatefulWidget {
  final List<RankingResult> results;

  const ResultTable({super.key, required this.results});

  @override
  State<ResultTable> createState() => _ResultTableState();
}

class _ResultTableState extends State<ResultTable> {
  bool _isExpanded = false;
  static const int _initialItemCount = 5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    // Determine which items to show
    final itemCount = widget.results.length;
    final showExpandButton = itemCount > _initialItemCount;
    final displayedResults = (_isExpanded || !showExpandButton) 
        ? widget.results 
        : widget.results.take(_initialItemCount).toList();

    return Column(
      children: [
        Container(
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
                    color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70, // Increased width
                        child: Center( // Center alignment
                          child: Text(
                            l10n.translate('rank'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Added spacing
                      Expanded(
                        child: Text(
                          l10n.translate('alternative'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          l10n.translate('score'),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data rows
                ...displayedResults.map((res) => _buildResultRow(context, res)),
              ],
            ),
          ),
        ),
        
        // Expand/Collapse Button
        if (showExpandButton)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
              ),
              label: Text(
                _isExpanded 
                  ? l10n.translate('showLess')
                  : l10n.translate('showMore').replaceAll('{count}', '${itemCount - _initialItemCount}'),
              ),
            ),
          ),
      ],
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
            color: colorScheme.outlineVariant.withAlpha(100),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank circle - aligned with history detail design
          SizedBox(
            width: 70, // Increased width
            child: Center( // Center alignment
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
          ),
          const SizedBox(width: 16), // Added spacing
          // Alternative name with flexible space
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                res.alternativeName,
                style: TextStyle(
                  fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
              ),
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
