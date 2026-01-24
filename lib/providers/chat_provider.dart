import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/decision_session.dart';
import '../models/criterion.dart';
import '../models/alternative.dart';
import '../services/deepseek_service.dart';
import '../services/firebase_service.dart';
import '../logic/dss_engine.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatState {
  final List<ChatMessage> messages;
  final DecisionSession? session;
  final bool isLoading;

  ChatState({required this.messages, this.session, this.isLoading = false});

  ChatState copyWith({
    List<ChatMessage>? messages,
    DecisionSession? session,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(DeepSeekService(), FirebaseService());
});

class ChatNotifier extends StateNotifier<ChatState> {
  final DeepSeekService _aiService;
  final FirebaseService _firebaseService;

  ChatNotifier(this._aiService, this._firebaseService)
    : super(ChatState(messages: [], session: null)) {
    _initSession();
  }

  void startNewDecision() {
    _initSession();
  }

  void _initSession() {
    final session = DecisionSession(
      id: const Uuid().v4(),
      title: 'New Decision',
      criteria: [],
      alternatives: [],
      createdAt: DateTime.now(),
      status: 'gathering',
    );
    state = ChatState(
      session: session,
      messages: [
        ChatMessage(
          content:
              "Hello! I'm your AI decision assistant. What would you like to decide today?",
          isUser: false,
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(content: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final history = state.messages
          .map(
            (m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList();

      final aiResponse = await _aiService.getChatResponse(history);

      final assistantMessage = ChatMessage(content: aiResponse, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );

      // Proactively try to extract structured data
      _extractData();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            content: "Sorry, I had trouble connecting. Please try again.",
            isUser: false,
          ),
        ],
      );
    }
  }

  Future<void> _extractData() async {
    final history = state.messages
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    final data = await _aiService.extractStructuredData(history);
    if (data != null) {
      try {
        final session = DecisionSession(
          id: state.session!.id,
          title: data['title'] ?? state.session!.title,
          criteria:
              (data['criteria'] as List?)
                  ?.map(
                    (c) => Criterion(
                      id: c['name'],
                      name: c['name'],
                      weight: (c['weight'] as num?)?.toDouble() ?? 1.0,
                      type: c['type'] == 'cost'
                          ? CriterionType.cost
                          : CriterionType.benefit,
                    ),
                  )
                  .toList() ??
              [],
          alternatives:
              (data['alternatives'] as List?)
                  ?.map(
                    (a) => Alternative(
                      id: a['name'],
                      name: a['name'],
                      scores:
                          (a['scores'] as Map<String, dynamic>?)?.map(
                            (k, v) => MapEntry(k, (v as num).toDouble()),
                          ) ??
                          {},
                    ),
                  )
                  .toList() ??
              [],
          createdAt: state.session!.createdAt,
          status: data['status'] ?? 'gathering',
        );

        state = state.copyWith(session: session);
        _firebaseService.saveSession(session);
      } catch (e) {
        debugPrint("Mapping error: $e");
      }
    }
  }

  void calculateRanking(DSSMethod method) {
    if (state.session == null) return;

    final results = DSSEngine.calculate(
      state.session!.criteria,
      state.session!.alternatives,
      method,
    );

    final updatedSession = DecisionSession(
      id: state.session!.id,
      title: state.session!.title,
      criteria: state.session!.criteria,
      alternatives: state.session!.alternatives,
      selectedMethod: method,
      results: results,
      createdAt: state.session!.createdAt,
      status: 'calculated',
    );

    state = state.copyWith(session: updatedSession);
    _firebaseService.saveSession(updatedSession);
  }
}
