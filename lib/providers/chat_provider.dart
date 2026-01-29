import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/decision_session.dart';
import '../models/criterion.dart';
import '../models/alternative.dart';
import '../services/deepseek_service.dart';
import '../services/firebase_service.dart';
import '../logic/dss_engine.dart';
import 'auth_provider.dart';

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
  final bool isDirty; // Track if user made any changes

  ChatState({
    required this.messages,
    this.session,
    this.isLoading = false,
    this.isDirty = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    DecisionSession? session,
    bool? isLoading,
    bool? isDirty,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Provider for FirebaseService with user ID injected
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final service = FirebaseService();
  service.setUserId(userId);
  return service;
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return ChatNotifier(DeepSeekService(), firebaseService);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final DeepSeekService _aiService;
  final FirebaseService _firebaseService;

  ChatNotifier(this._aiService, this._firebaseService)
    : super(ChatState(messages: [], session: null)) {
    // Default to 'en' if not specified during init
    _initSession();
  }

  void startNewDecision({String languageCode = 'en'}) {
    _initSession(languageCode: languageCode);
  }

  /// Start a new decision using data from an existing history session
  /// Creates a NEW session with NEW id and timestamp, copies data from history
  void startFromHistory(DecisionSession historySession, {String languageCode = 'en'}) {
    final newSession = DecisionSession(
      id: const Uuid().v4(), // New unique ID
      title: historySession.title,
      criteria: List.from(historySession.criteria), // Copy criteria
      alternatives: List.from(historySession.alternatives), // Copy alternatives
      createdAt: DateTime.now(), // New timestamp
      status: 'gathering', // Reset status
      // Don't copy results - user may want to recalculate
    );

    final welcomeBackMsg = languageCode == 'id'
        ? "Selamat kembali! Saya telah memuat data keputusan Anda sebelumnya untuk '${historySession.title}'. Anda memiliki ${historySession.criteria.length} kriteria dan ${historySession.alternatives.length} alternatif yang siap. Apakah Anda ingin membuat perubahan atau melanjutkan untuk menghitung hasil?"
        : "Welcome back! I've loaded your previous decision data for '${historySession.title}'. You have ${historySession.criteria.length} criteria and ${historySession.alternatives.length} alternatives ready. Would you like to make any changes or proceed to calculate the results?";

    state = ChatState(
      session: newSession,
      messages: [
        ChatMessage(
          content: welcomeBackMsg,
          isUser: false,
        ),
      ],
    );
  }

  void _initSession({String languageCode = 'en'}) {
    final session = DecisionSession(
      id: const Uuid().v4(),
      title: 'New Decision',
      criteria: [],
      alternatives: [],
      createdAt: DateTime.now(),
      status: 'gathering',
    );

    final welcomeMsg = languageCode == 'id'
        ? "Halo! Saya asisten keputusan AI Anda. Apa yang ingin Anda putuskan hari ini?"
        : "Hello! I'm your AI decision assistant. What would you like to decide today?";

    state = ChatState(
      session: session,
      messages: [
        ChatMessage(
          content: welcomeMsg,
          isUser: false,
        ),
      ],
    );
  }

  Future<void> sendMessage(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(content: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      isDirty: true, // User interacted, mark as dirty
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

      final aiResponse = await _aiService.getChatResponse(history, languageCode: languageCode);

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
        final currentSession = state.session!;

        // 1. Title Merge
        final newTitle = data['title'] ?? currentSession.title;

        // 2. Criteria Merge
        // Only replace if extracted criteria is NOT empty
        final extractedCriteria = (data['criteria'] as List?)
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
            .toList();

        final newCriteria =
            (extractedCriteria != null && extractedCriteria.isNotEmpty)
            ? extractedCriteria
            : currentSession.criteria;

        // 3. Alternatives Merge
        final extractedAlternatives = (data['alternatives'] as List?)
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
            .toList();

        final newAlternatives =
            (extractedAlternatives != null && extractedAlternatives.isNotEmpty)
            ? extractedAlternatives
            : currentSession.alternatives;

        final session = DecisionSession(
          id: currentSession.id,
          title: newTitle,
          criteria: newCriteria,
          alternatives: newAlternatives,
          createdAt: currentSession.createdAt,
          status: data['status'] ?? currentSession.status,
        );

        debugPrint("--- Final Session for Firestore ---");
        debugPrint("Criteria count: ${session.criteria.length}");
        debugPrint("Alternatives count: ${session.alternatives.length}");
        debugPrint("Raw JSON: ${session.toJson()}");

        state = state.copyWith(session: session, isDirty: true);
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

    state = state.copyWith(session: updatedSession, isDirty: true);
    _firebaseService.saveSession(updatedSession);
  }
}
