import 'package:flutter/material.dart';
import '../../models/decision_session.dart';
import '../../l10n/app_localizations.dart';

class DecisionSummaryCard extends StatelessWidget {
  final DecisionSession session;

  const DecisionSummaryCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    // Status styling - aligned with history detail screen
    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (session.status) {
      case 'calculated':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = l10n.translate('calculated');
        break;
      case 'ready':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = l10n.translate('ready');
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.edit_note;
        statusText = l10n.translate('gathering');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row with icon - consistent with history detail
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      '${l10n.translate('currentStatus')}: $statusText',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Title row - with proper overflow handling
          _buildInfoRow(
            context,
            l10n.translate('title'),
            session.title,
            isTitle: true,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            l10n.translate('criteria'),
            '${session.criteria.length} ${l10n.translate('defined')}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            l10n.translate('alternatives'),
            '${session.alternatives.length} ${l10n.translate('defined')}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isTitle = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withAlpha(180),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTitle ? 15 : 14,
              color: colorScheme.onPrimaryContainer,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
