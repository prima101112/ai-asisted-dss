import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/decision_summary_card.dart';
import '../widgets/result_table.dart';
import '../widgets/method_selector.dart';
import '../widgets/app_scaffold.dart';
import 'history_screen.dart';
import '../../l10n/app_localizations.dart';

import '../../models/decision_session.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 10),
            const Text('About Smart DSS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This is a professional AI-assisted Decision Support System designed to help you make complex choices with clarity and mathematical precision.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Created by:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Text(
                    'Prima Adi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ade Dwi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.translate('appTitle'),
      onNewChat: () {
        ref.read(chatProvider.notifier).startNewDecision();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting new decision case...')),
        );
      },
      onHistoryTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'About',
          onPressed: () => _showAboutDialog(context),
        ),
        // Decision Insights panel toggle
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: l10n.translate('decisionInsights'),
              onPressed: () => _showInsightsPanel(context, chatState, chatNotifier),
            );
          },
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: _isInitialState(chatState)
                ? _buildHomeView(context, chatNotifier)
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final msg = chatState.messages[index];
                      return ChatBubble(message: msg.content, isUser: msg.isUser);
                    },
                  ),
          ),
          _buildInputArea(chatNotifier),
        ],
      ),
    );
  }

  /// Check if we're in initial state (only welcome message, no user interaction yet)
  /// Also returns false if session has pre-filled data from history
  bool _isInitialState(ChatState state) {
    // If session has criteria or alternatives, it's from "Use Again" - show chat view
    if (state.session != null && 
        (state.session!.criteria.isNotEmpty || state.session!.alternatives.isNotEmpty)) {
      return false;
    }
    return state.messages.length == 1 && 
           !state.messages.first.isUser &&
           !state.isLoading;
  }

  /// Build Gemini-style home view with greeting and suggestions
  Widget _buildHomeView(BuildContext context, ChatNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final firstName = user?.displayName?.split(' ').first ?? 'User';
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Greeting
          Text(
            '${l10n.translate('helloGreeting')} $firstName 👋',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.translate('whatHelp'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          
          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                emoji: '🎯',
                label: l10n.translate('chooseBestOption'),
                onTap: () => _sendSuggestion(notifier, 'I want to compare several options and find the best one'),
              ),
              _SuggestionChip(
                emoji: '💼',
                label: l10n.translate('jobCareer'),
                onTap: () => _sendSuggestion(notifier, 'I need help deciding between job opportunities'),
              ),
              _SuggestionChip(
                emoji: '🛒',
                label: l10n.translate('purchaseDecision'),
                onTap: () => _sendSuggestion(notifier, 'I want to compare products before making a purchase'),
              ),
              _SuggestionChip(
                emoji: '🏠',
                label: l10n.translate('locationPlace'),
                onTap: () => _sendSuggestion(notifier, 'I need help choosing between different locations'),
              ),
              _SuggestionChip(
                emoji: '📊',
                label: l10n.translate('businessStrategy'),
                onTap: () => _sendSuggestion(notifier, 'I want to evaluate business strategies or investments'),
              ),
              _SuggestionChip(
                emoji: '✨',
                label: l10n.translate('somethingElse'),
                onTap: () => _sendSuggestion(notifier, 'I have a decision to make'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendSuggestion(ChatNotifier notifier, String message) {
    final languageCode = ref.read(localeProvider).languageCode;
    notifier.sendMessage(message, languageCode: languageCode);
    _scrollToBottom();
  }

  void _showInsightsPanel(BuildContext context, ChatState chatState, ChatNotifier chatNotifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          // Watch the provider to rebuild when state changes
          final currentState = ref.watch(chatProvider);
          final notifier = ref.read(chatProvider.notifier);
          final l10n = AppLocalizations.of(context);
          
          // Auto-expand to full height when results are available
          final hasResults = currentState.session?.results != null &&
              currentState.session!.results!.isNotEmpty;
          
          return DraggableScrollableSheet(
            initialChildSize: hasResults ? 0.9 : 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('decisionInsights'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (currentState.session != null) ...[
                    DecisionSummaryCard(session: currentState.session!),
                    const SizedBox(height: 24),
                    if (currentState.session!.alternatives.isNotEmpty &&
                        currentState.session!.criteria.isNotEmpty) ...[
                      MethodSelector(
                        currentMethod: currentState.session!.selectedMethod,
                        onSelected: (method) {
                          notifier.calculateRanking(method);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (currentState.session!.results != null &&
                        currentState.session!.results!.isNotEmpty) ...[
                      Text(
                        l10n.translate('rankings'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ResultTable(
                        results: currentState.session!.results!,
                      ),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.translate('gatherMoreInfo'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.translate('startConversation'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(ChatNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final chatState = ref.watch(chatProvider);
    final isReady = chatState.session?.status == 'ready';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (isReady) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      l10n.translate('selectMethod'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MethodChip(
                      label: 'SAW',
                      onTap: () {
                         final languageCode = ref.read(localeProvider).languageCode;
                         notifier.sendMessage(
                           languageCode == 'id' 
                             ? 'Hitung menggunakan metode SAW' 
                             : 'Calculate using SAW method', 
                           languageCode: languageCode
                         );
                         notifier.calculateRanking(DSSMethod.saw);
                         _scrollToBottom();
                      },
                    ),
                    const SizedBox(width: 8),
                    _MethodChip(
                      label: 'WP',
                      onTap: () {
                         final languageCode = ref.read(localeProvider).languageCode;
                         notifier.sendMessage(
                           languageCode == 'id' 
                             ? 'Hitung menggunakan metode WP' 
                             : 'Calculate using WP method',
                           languageCode: languageCode
                         );
                         notifier.calculateRanking(DSSMethod.wp);
                         _scrollToBottom();
                      },
                    ),
                    const SizedBox(width: 8),
                    _MethodChip(
                      label: 'TOPSIS',
                      onTap: () {
                         final languageCode = ref.read(localeProvider).languageCode;
                         notifier.sendMessage(
                           languageCode == 'id' 
                             ? 'Hitung menggunakan metode TOPSIS' 
                             : 'Calculate using TOPSIS method',
                           languageCode: languageCode
                         );
                         notifier.calculateRanking(DSSMethod.topsis);
                         _scrollToBottom();
                      },
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: l10n.translate('typeMessage'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withAlpha(127),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (val) {
                      final languageCode = ref.read(localeProvider).languageCode;
                      notifier.sendMessage(val, languageCode: languageCode);
                      _controller.clear();
                      _scrollToBottom();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final languageCode = ref.read(localeProvider).languageCode;
                      notifier.sendMessage(_controller.text, languageCode: languageCode);
                      _controller.clear();
                      _scrollToBottom();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(150),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
