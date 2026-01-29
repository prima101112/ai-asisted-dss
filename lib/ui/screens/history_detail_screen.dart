import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/decision_session.dart';
import '../../models/criterion.dart';
import '../../models/alternative.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final DecisionSession session;

  const HistoryDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy • HH:mm');

    // Determine status styling
    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (session.status) {
      case 'calculated':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'ready':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Ready to Calculate';
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.edit_note;
        statusText = 'In Progress';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Decision Detail'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withAlpha(150),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    session.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onPrimaryContainer.withAlpha(180),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(session.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onPrimaryContainer.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.checklist,
                    label: 'Criteria',
                    value: '${session.criteria.length}',
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.compare_arrows,
                    label: 'Alternatives',
                    value: '${session.alternatives.length}',
                    color: colorScheme.secondary,
                  ),
                ),
                if (session.selectedMethod != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.functions,
                      label: 'Method',
                      value: session.selectedMethod!.name.toUpperCase(),
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Results Section (with medals)
            if (session.results != null && session.results!.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.emoji_events,
                title: 'Rankings',
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              ...session.results!.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                return _RankingCard(
                  rank: result.rank,
                  name: result.alternativeName,
                  score: result.score,
                  isTop3: index < 3,
                );
              }),
              const SizedBox(height: 24),
            ],

            // Criteria Section
            _SectionHeader(
              icon: Icons.tune,
              title: 'Criteria Details',
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 12),
            ...session.criteria.map((c) => _CriteriaCard(criterion: c)),

            const SizedBox(height: 24),

            // Alternatives Section
            _SectionHeader(
              icon: Icons.list_alt,
              title: 'Alternatives',
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            ...session.alternatives.map((a) => _AlternativeCard(alternative: a)),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).startFromHistory(session);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.replay),
                label: const Text(
                  'Use This Data Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final String name;
  final double score;
  final bool isTop3;

  const _RankingCard({
    required this.rank,
    required this.name,
    required this.score,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Medal colors based on rank
    Color? medalColor;
    IconData medalIcon = Icons.emoji_events;
    
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop3 
            ? medalColor?.withAlpha(20) ?? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: isTop3 && medalColor != null
            ? Border.all(color: medalColor.withAlpha(100), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank indicator
          if (isTop3 && medalColor != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    medalColor,
                    medalColor.withAlpha(180),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                medalIcon,
                color: Colors.white,
                size: 24,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.outline.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
          // Name and score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rank #$rank',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isTop3 && medalColor != null
                  ? medalColor.withAlpha(30)
                  : colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score.toStringAsFixed(4),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isTop3 && medalColor != null
                    ? medalColor
                    : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  final Criterion criterion;

  const _CriteriaCard({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBenefit = criterion.type == CriterionType.benefit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isBenefit ? Colors.green : Colors.red).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isBenefit ? Icons.trending_up : Icons.trending_down,
              color: isBenefit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criterion.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isBenefit ? 'Benefit (Higher is better)' : 'Cost (Lower is better)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Weight: ${criterion.weight}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  final Alternative alternative;

  const _AlternativeCard({required this.alternative});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alternative.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (alternative.scores.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.outline.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${alternative.scores.length} scores',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
