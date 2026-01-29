import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/decision_summary_card.dart';
import '../widgets/result_table.dart';
import '../widgets/method_selector.dart';
import '../widgets/app_scaffold.dart';
import 'history_screen.dart';

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

    return AppScaffold(
      title: 'AI Decision Assistant',
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
              tooltip: 'Decision Insights',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Greeting
          Text(
            'Hi $firstName 👋',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What decision do you\nneed help with?',
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
                label: 'Choose best option',
                onTap: () => _sendSuggestion(notifier, 'I want to compare several options and find the best one'),
              ),
              _SuggestionChip(
                emoji: '💼',
                label: 'Job or career decision',
                onTap: () => _sendSuggestion(notifier, 'I need help deciding between job opportunities'),
              ),
              _SuggestionChip(
                emoji: '🛒',
                label: 'Purchase decision',
                onTap: () => _sendSuggestion(notifier, 'I want to compare products before making a purchase'),
              ),
              _SuggestionChip(
                emoji: '🏠',
                label: 'Location or place',
                onTap: () => _sendSuggestion(notifier, 'I need help choosing between different locations'),
              ),
              _SuggestionChip(
                emoji: '📊',
                label: 'Business strategy',
                onTap: () => _sendSuggestion(notifier, 'I want to evaluate business strategies or investments'),
              ),
              _SuggestionChip(
                emoji: '✨',
                label: 'Something else',
                onTap: () => _sendSuggestion(notifier, 'I have a decision to make'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendSuggestion(ChatNotifier notifier, String message) {
    notifier.sendMessage(message);
    _scrollToBottom();
  }

  void _showInsightsPanel(BuildContext context, ChatState chatState, ChatNotifier chatNotifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
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
                'Decision Insights',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (chatState.session != null) ...[
                DecisionSummaryCard(session: chatState.session!),
                const SizedBox(height: 24),
                if (chatState.session!.alternatives.isNotEmpty &&
                    chatState.session!.criteria.isNotEmpty) ...[
                  MethodSelector(
                    currentMethod: chatState.session!.selectedMethod,
                    onSelected: (method) {
                      chatNotifier.calculateRanking(method);
                      // Sheet stays open to show results
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                if (chatState.session!.results != null &&
                    chatState.session!.results!.isNotEmpty) ...[
                  const Text(
                    'Rankings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResultTable(
                    results: chatState.session!.results!,
                  ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gather more info or select a method to see results.',
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
                      'Start a conversation to gather decision data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatNotifier notifier) {
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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
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
                  notifier.sendMessage(val);
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
                  notifier.sendMessage(_controller.text);
                  _controller.clear();
                  _scrollToBottom();
                },
              ),
            ),
          ],
        ),
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
