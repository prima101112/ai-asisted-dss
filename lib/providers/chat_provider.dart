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
  void startFromHistory(
    DecisionSession historySession, {
    String languageCode = 'en',
  }) {
    // Determine initial status based on data
    final hasData =
        historySession.criteria.isNotEmpty &&
        historySession.alternatives.isNotEmpty;
    final initialStatus = hasData ? 'ready' : 'gathering';

    final newSession = DecisionSession(
      id: const Uuid().v4(), // New unique ID
      title: historySession.title,
      criteria: List.from(historySession.criteria), // Copy criteria
      alternatives: List.from(historySession.alternatives), // Copy alternatives
      createdAt: DateTime.now(), // New timestamp
      status: initialStatus,
      // Don't copy results - user may want to recalculate
    );

    debugPrint(
      "Loaded from history: ${newSession.criteria.length} criteria, ${newSession.alternatives.length} alternatives",
    );
    for (var c in newSession.criteria) {
      debugPrint("  Criterion: ${c.name} (weight: ${c.weight})");
    }
    for (var a in newSession.alternatives) {
      debugPrint("  Alternative: ${a.name}");
    }

    final welcomeBackMsg = languageCode == 'id'
        ? "Selamat kembali! Saya telah memuat data keputusan Anda sebelumnya untuk '${historySession.title}'. Anda memiliki ${historySession.criteria.length} kriteria dan ${historySession.alternatives.length} alternatif yang siap. Apakah Anda ingin membuat perubahan atau melanjutkan untuk menghitung hasil?"
        : "Welcome back! I've loaded your previous decision data for '${historySession.title}'. You have ${historySession.criteria.length} criteria and ${historySession.alternatives.length} alternatives ready. Would you like to make any changes or proceed to calculate the results?";

    state = ChatState(
      session: newSession,
      messages: [ChatMessage(content: welcomeBackMsg, isUser: false)],
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
      messages: [ChatMessage(content: welcomeMsg, isUser: false)],
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

      final aiResponse = await _aiService.getChatResponse(
        history,
        languageCode: languageCode,
        session: state.session,
      );

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

    final data = await _aiService.extractStructuredData(
      history,
      session: state.session,
    );
    if (data != null) {
      try {
        final currentSession = state.session!;

        // 1. Title Merge
        final newTitle = data['title'] ?? currentSession.title;

        // 2. Criteria Merge
        final extractedCriteria = (data['criteria'] as List?)
            ?.map(
              (c) => Criterion(
                id: c['name'], // Using name as ID for now
                name: c['name'],
                weight: (c['weight'] as num?)?.toDouble() ?? 1.0,
                type: c['type'] == 'cost'
                    ? CriterionType.cost
                    : CriterionType.benefit,
              ),
            )
            .toList();

        final List<Criterion> mergedCriteria = List.from(
          currentSession.criteria,
        );
        if (extractedCriteria != null) {
          for (var extracted in extractedCriteria) {
            final index = mergedCriteria.indexWhere(
              (existing) => existing.name == extracted.name,
            );
            if (index != -1) {
              // Update existing
              mergedCriteria[index] = Criterion(
                id: mergedCriteria[index].id,
                name: extracted.name,
                weight: extracted.weight,
                type: extracted.type,
              );
            } else {
              // Add new
              mergedCriteria.add(extracted);
            }
          }
        }
        final newCriteria = mergedCriteria;

        // 3. Alternatives Merge
        final extractedAlternatives = (data['alternatives'] as List?)
            ?.map(
              (a) => Alternative(
                id: a['name'], // Using name as ID for now
                name: a['name'],
                scores:
                    (a['scores'] as Map<String, dynamic>?)?.map(
                      (k, v) => MapEntry(k, (v as num).toDouble()),
                    ) ??
                    {},
              ),
            )
            .toList();

        final List<Alternative> mergedAlternatives = List.from(
          currentSession.alternatives,
        );
        if (extractedAlternatives != null) {
          for (var extracted in extractedAlternatives) {
            final index = mergedAlternatives.indexWhere(
              (existing) => existing.name == extracted.name,
            );
            if (index != -1) {
              // Merge scores
              final updatedScores = Map<String, double>.from(
                mergedAlternatives[index].scores,
              );
              updatedScores.addAll(extracted.scores);

              mergedAlternatives[index] = Alternative(
                id: mergedAlternatives[index].id,
                name: extracted.name,
                scores: updatedScores,
              );
            } else {
              // Add new
              mergedAlternatives.add(extracted);
            }
          }
        }
        final newAlternatives = mergedAlternatives;

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

    final result = DSSEngine.calculate(
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
      results: result.rankings,
      calculationMatrices: result.matrices,
      createdAt: state.session!.createdAt,
      status: 'calculated',
    );

    state = state.copyWith(session: updatedSession, isDirty: true);
    _firebaseService.saveSession(updatedSession);
  }

  Future<void> deleteSession(String id) async {
    await _firebaseService.deleteSession(id);
    // If deleted session is the current one, reset chat
    if (state.session?.id == id) {
      _initSession();
    }
  }
}
