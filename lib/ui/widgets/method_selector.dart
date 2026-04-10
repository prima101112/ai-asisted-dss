import 'package:flutter/material.dart';
import '../../models/decision_session.dart';
import '../../l10n/app_localizations.dart';

class MethodSelector extends StatelessWidget {
  final Function(DSSMethod) onSelected;
  final DSSMethod? currentMethod;
  final bool enabled;

  const MethodSelector({
    super.key,
    required this.onSelected,
    this.currentMethod,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('selectMethod'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: DSSMethod.values.map((method) {
            final isSelected = currentMethod == method;
            return ChoiceChip(
              label: Text(method.toString().split('.').last.toUpperCase()),
              selected: isSelected,
              onSelected: enabled ? (_) => onSelected(method) : null,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withAlpha(50),
            );
          }).toList(),
        ),
      ],
    );
  }
}
