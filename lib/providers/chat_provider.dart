import 'dart:async';

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
  final bool isSyncing;
  final bool isDirty; // Track if user made any changes

  ChatState({
    required this.messages,
    this.session,
    this.isLoading = false,
    this.isSyncing = false,
    this.isDirty = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    DecisionSession? session,
    bool? isLoading,
    bool? isSyncing,
    bool? isDirty,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
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
  static const String _defaultDecisionTitle = '';
  int _latestExtractionToken = 0;

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
    final initialStatus = _deriveStatus(
      title: historySession.title,
      criteria: historySession.criteria,
      alternatives: historySession.alternatives,
    );

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
      title: _defaultDecisionTitle,
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
    if (text.trim().isEmpty || state.isLoading || state.session == null) return;

    final trimmedText = text.trim();
    final session = state.session!;
    final requestedMethod = _detectRequestedMethod(trimmedText);

    final userMessage = ChatMessage(content: trimmedText, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isDirty: true, // User interacted, mark as dirty
    );

    if (requestedMethod != null &&
        _looksLikeMethodExecutionRequest(trimmedText, session)) {
      await _handleMethodRequest(requestedMethod, languageCode: languageCode);
      return;
    }

    state = state.copyWith(isLoading: true);

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
      final updatedMessages = [...state.messages, assistantMessage];
      state = state.copyWith(messages: updatedMessages, isLoading: false);

      // Extract structured data in the background so chat loading ends
      // as soon as the visible assistant reply is on screen.
      _scheduleExtractData(updatedMessages);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            content: _connectionErrorMessage(languageCode),
            isUser: false,
          ),
        ],
      );
    }
  }

  void _scheduleExtractData(List<ChatMessage> messageSnapshot) {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    final extractionToken = ++_latestExtractionToken;
    state = state.copyWith(isSyncing: true);
    unawaited(
      _extractData(
        extractionToken: extractionToken,
        sessionId: sessionId,
        messageSnapshot: messageSnapshot,
      ),
    );
  }

  Future<void> _extractData({
    required int extractionToken,
    required String sessionId,
    required List<ChatMessage> messageSnapshot,
  }) async {
    final activeSession = state.session;
    if (activeSession == null) {
      _finishSyncIfCurrent(extractionToken);
      return;
    }

    final history = messageSnapshot
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    final data = await _aiService.extractStructuredData(
      history,
      session: activeSession,
    );
    if (data != null) {
      try {
        if (!_canApplyExtraction(extractionToken, sessionId, messageSnapshot)) {
          return;
        }

        final currentSession = state.session;
        if (currentSession == null) return;

        // 1. Title Merge
        final extractedTitle = (data['title'] as String?)?.trim();
        final newTitle = (extractedTitle?.isNotEmpty ?? false)
            ? extractedTitle!
            : currentSession.title;

        // 2. Criteria Merge
        final extractedCriteria = (data['criteria'] as List?)
            ?.map(
              (c) => Criterion(
                id: _slugify(c['name']),
                name: (c['name'] as String).trim(),
                weight: (c['weight'] as num?)?.toDouble() ?? 1.0,
                type: c['type'] == 'cost'
                    ? CriterionType.cost
                    : CriterionType.benefit,
              ),
            )
            .where((criterion) => criterion.name.isNotEmpty)
            .toList();

        final List<Criterion> mergedCriteria = List.from(
          currentSession.criteria,
        );
        if (extractedCriteria != null) {
          for (var extracted in extractedCriteria) {
            final index = mergedCriteria.indexWhere(
              (existing) =>
                  _normalizedName(existing.name) ==
                  _normalizedName(extracted.name),
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
        final criterionIdLookup = _buildCriterionIdLookup(newCriteria);
        final extractedAlternatives = (data['alternatives'] as List?)
            ?.map(
              (a) => Alternative(
                id: _slugify(a['name']),
                name: (a['name'] as String).trim(),
                scores: _normalizeScores(
                  a['scores'] as Map<String, dynamic>?,
                  criterionIdLookup,
                ),
              ),
            )
            .where((alternative) => alternative.name.isNotEmpty)
            .toList();

        final List<Alternative> mergedAlternatives = List.from(
          currentSession.alternatives,
        );
        if (extractedAlternatives != null) {
          for (var extracted in extractedAlternatives) {
            final index = mergedAlternatives.indexWhere(
              (existing) =>
                  _normalizedName(existing.name) ==
                  _normalizedName(extracted.name),
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
        final decisionDataChanged = _hasDecisionDataChanged(
          currentSession: currentSession,
          newTitle: newTitle,
          newCriteria: newCriteria,
          newAlternatives: newAlternatives,
        );
        final keepCalculatedResults =
            !decisionDataChanged &&
            currentSession.results != null &&
            currentSession.results!.isNotEmpty;

        final session = DecisionSession(
          id: currentSession.id,
          title: newTitle,
          criteria: newCriteria,
          alternatives: newAlternatives,
          selectedMethod: keepCalculatedResults
              ? currentSession.selectedMethod
              : null,
          results: keepCalculatedResults ? currentSession.results : null,
          calculationMatrices: keepCalculatedResults
              ? currentSession.calculationMatrices
              : null,
          createdAt: currentSession.createdAt,
          status: _deriveStatus(
            title: newTitle,
            criteria: newCriteria,
            alternatives: newAlternatives,
            hasResults: keepCalculatedResults,
          ),
        );

        debugPrint("--- Final Session for Firestore ---");
        debugPrint("Criteria count: ${session.criteria.length}");
        debugPrint("Alternatives count: ${session.alternatives.length}");
        debugPrint("Raw JSON: ${session.toJson()}");

        state = state.copyWith(session: session, isDirty: true);
        await _firebaseService.saveSession(session);
      } catch (e) {
        debugPrint("Mapping error: $e");
      } finally {
        _finishSyncIfCurrent(extractionToken);
      }
    } else {
      _finishSyncIfCurrent(extractionToken);
    }
  }

  Future<bool> calculateRanking(
    DSSMethod method, {
    String? languageCode,
  }) async {
    final session = state.session;
    if (state.isLoading || session == null) return false;

    final validationError = _validateSessionForMethod(
      session,
      method,
      languageCode,
    );
    if (validationError != null) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(content: validationError, isUser: false),
        ],
      );
      return false;
    }

    final result = DSSEngine.calculate(
      session.criteria,
      session.alternatives,
      method,
    );

    final updatedSession = DecisionSession(
      id: session.id,
      title: session.title,
      criteria: session.criteria,
      alternatives: session.alternatives,
      selectedMethod: method,
      results: result.rankings,
      calculationMatrices: result.matrices,
      createdAt: session.createdAt,
      status: 'calculated',
    );

    state = state.copyWith(session: updatedSession, isDirty: true);
    await _firebaseService.saveSession(updatedSession);
    return true;
  }

  Future<void> calculateRankingAndAnalyze(
    DSSMethod method, {
    String? languageCode,
  }) async {
    final didCalculate = await calculateRanking(
      method,
      languageCode: languageCode,
    );
    if (!didCalculate) return;
    await analyzeCurrentResults(languageCode: languageCode);
  }

  Future<void> analyzeCurrentResults({String? languageCode}) async {
    final session = state.session;
    if (state.isLoading ||
        session == null ||
        session.results == null ||
        session.results!.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final aiResponse = await _aiService.getCalculationAnalysis(
        session,
        languageCode: languageCode,
      );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(content: aiResponse, isUser: false),
        ],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            content: _connectionErrorMessage(languageCode),
            isUser: false,
          ),
        ],
        isLoading: false,
      );
    }
  }

  Future<void> deleteSession(String id) async {
    await _firebaseService.deleteSession(id);
    // If deleted session is the current one, reset chat
    if (state.session?.id == id) {
      _initSession();
    }
  }

  Future<void> _handleMethodRequest(
    DSSMethod method, {
    String? languageCode,
  }) async {
    final session = state.session;
    if (session == null) return;

    final shouldRecalculate =
        session.selectedMethod != method ||
        session.results == null ||
        session.results!.isEmpty;

    if (shouldRecalculate) {
      await calculateRankingAndAnalyze(method, languageCode: languageCode);
      return;
    }

    await analyzeCurrentResults(languageCode: languageCode);
  }

  String _deriveStatus({
    required String title,
    required List<Criterion> criteria,
    required List<Alternative> alternatives,
    bool hasResults = false,
  }) {
    if (hasResults) return 'calculated';
    return _isDecisionReady(title, criteria, alternatives)
        ? 'ready'
        : 'gathering';
  }

  bool _isDecisionReady(
    String title,
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    if (!_hasMeaningfulTitle(title) ||
        criteria.isEmpty ||
        alternatives.isEmpty) {
      return false;
    }

    final validCriteria = criteria.every(
      (criterion) =>
          criterion.name.trim().isNotEmpty &&
          criterion.weight.isFinite &&
          criterion.weight > 0,
    );
    if (!validCriteria) return false;

    final validAlternatives = alternatives.every(
      (alternative) => alternative.name.trim().isNotEmpty,
    );
    if (!validAlternatives) return false;

    return _hasCompleteScores(criteria, alternatives);
  }

  bool _hasMeaningfulTitle(String title) => title.trim().isNotEmpty;

  bool _hasCompleteScores(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    for (final alternative in alternatives) {
      for (final criterion in criteria) {
        final score = alternative.scores[criterion.id];
        if (score == null || !score.isFinite) {
          return false;
        }
      }
    }
    return true;
  }

  bool _hasPositiveScores(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    for (final alternative in alternatives) {
      for (final criterion in criteria) {
        final score = alternative.scores[criterion.id];
        if (score == null || score <= 0) {
          return false;
        }
      }
    }
    return true;
  }

  String? _validateSessionForMethod(
    DecisionSession session,
    DSSMethod method,
    String? languageCode,
  ) {
    if (!_isDecisionReady(
      session.title,
      session.criteria,
      session.alternatives,
    )) {
      return languageCode == 'id'
          ? 'Data keputusan belum lengkap. Pastikan judul, kriteria, alternatif, dan semua skor sudah terisi sebelum menghitung.'
          : 'The decision data is incomplete. Fill in the title, criteria, alternatives, and all scores before calculating.';
    }

    if (method == DSSMethod.wp &&
        !_hasPositiveScores(session.criteria, session.alternatives)) {
      return languageCode == 'id'
          ? 'Metode WP membutuhkan semua skor bernilai lebih dari 0. Perbaiki nilai 0 atau negatif terlebih dahulu.'
          : 'The WP method requires every score to be greater than 0. Fix any zero or negative values first.';
    }

    return null;
  }

  Map<String, double> _normalizeScores(
    Map<String, dynamic>? rawScores,
    Map<String, String> criterionIdLookup,
  ) {
    if (rawScores == null || rawScores.isEmpty) {
      return {};
    }

    final normalizedScores = <String, double>{};
    for (final entry in rawScores.entries) {
      final value = entry.value;
      if (value is! num) continue;

      final normalizedKey = _normalizedName(entry.key);
      final criterionId =
          criterionIdLookup[normalizedKey] ?? _slugify(entry.key);
      normalizedScores[criterionId] = value.toDouble();
    }
    return normalizedScores;
  }

  Map<String, String> _buildCriterionIdLookup(List<Criterion> criteria) {
    final lookup = <String, String>{};
    for (final criterion in criteria) {
      lookup[_normalizedName(criterion.name)] = criterion.id;
      lookup[_normalizedName(criterion.id)] = criterion.id;
    }
    return lookup;
  }

  bool _hasDecisionDataChanged({
    required DecisionSession currentSession,
    required String newTitle,
    required List<Criterion> newCriteria,
    required List<Alternative> newAlternatives,
  }) {
    if (currentSession.title.trim() != newTitle.trim()) {
      return true;
    }

    if (!_sameCriteria(currentSession.criteria, newCriteria)) {
      return true;
    }

    if (!_sameAlternatives(currentSession.alternatives, newAlternatives)) {
      return true;
    }

    return false;
  }

  bool _sameCriteria(List<Criterion> left, List<Criterion> right) {
    if (left.length != right.length) return false;

    final leftMap = {
      for (final criterion in left)
        criterion.id: (criterion.name.trim(), criterion.weight, criterion.type),
    };
    final rightMap = {
      for (final criterion in right)
        criterion.id: (criterion.name.trim(), criterion.weight, criterion.type),
    };

    if (leftMap.length != rightMap.length) return false;

    for (final entry in leftMap.entries) {
      final other = rightMap[entry.key];
      if (other == null || other != entry.value) {
        return false;
      }
    }

    return true;
  }

  bool _sameAlternatives(List<Alternative> left, List<Alternative> right) {
    if (left.length != right.length) return false;

    final leftMap = {
      for (final alternative in left)
        alternative.id: _sortedScoresSignature(alternative.scores),
    };
    final rightMap = {
      for (final alternative in right)
        alternative.id: _sortedScoresSignature(alternative.scores),
    };

    if (leftMap.length != rightMap.length) return false;

    for (final alternative in left) {
      final rightAlternative = right.firstWhere(
        (candidate) => candidate.id == alternative.id,
        orElse: () => Alternative(id: '', name: '', scores: const {}),
      );
      if (rightAlternative.id.isEmpty ||
          rightAlternative.name.trim() != alternative.name.trim()) {
        return false;
      }
    }

    for (final entry in leftMap.entries) {
      final other = rightMap[entry.key];
      if (other == null || other.length != entry.value.length) {
        return false;
      }
      for (final scoreEntry in entry.value.entries) {
        if (other[scoreEntry.key] != scoreEntry.value) {
          return false;
        }
      }
    }

    return true;
  }

  Map<String, double> _sortedScoresSignature(Map<String, double> scores) {
    final sortedKeys = scores.keys.toList()..sort();
    return {for (final key in sortedKeys) key: scores[key]!};
  }

  String _normalizedName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _slugify(Object? value) {
    final slug = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? const Uuid().v4() : slug;
  }

  String _connectionErrorMessage(String? languageCode) {
    return languageCode == 'id'
        ? 'Maaf, saya mengalami masalah koneksi. Silakan coba lagi.'
        : 'Sorry, I had trouble connecting. Please try again.';
  }

  DSSMethod? _detectRequestedMethod(String text) {
    final normalized = text.toLowerCase();
    final matchedMethods = <DSSMethod>{};

    if (RegExp(r'\bsaw\b').hasMatch(normalized)) {
      matchedMethods.add(DSSMethod.saw);
    }
    if (RegExp(r'\bwp\b|\bweighted product\b').hasMatch(normalized)) {
      matchedMethods.add(DSSMethod.wp);
    }
    if (RegExp(r'\btopsis\b').hasMatch(normalized)) {
      matchedMethods.add(DSSMethod.topsis);
    }

    if (matchedMethods.length != 1) {
      return null;
    }

    return matchedMethods.first;
  }

  bool _looksLikeMethodExecutionRequest(String text, DecisionSession session) {
    final normalized = text.toLowerCase();

    final hasActionKeyword = RegExp(
      r'\b('
      r'analisis|analyze|analyse|jelaskan|explain|hitung|calculate|'
      r'gunakan|pakai|use|run|hitungkan|ranking|rank|hasil|result|'
      r'peringkat|metode|method'
      r')\b',
    ).hasMatch(normalized);

    if (!hasActionKeyword) {
      return false;
    }

    return session.criteria.isNotEmpty && session.alternatives.isNotEmpty;
  }

  bool _canApplyExtraction(
    int extractionToken,
    String sessionId,
    List<ChatMessage> messageSnapshot,
  ) {
    final currentSession = state.session;
    if (currentSession == null || currentSession.id != sessionId) {
      _finishSyncIfCurrent(extractionToken);
      return false;
    }

    if (_latestExtractionToken != extractionToken) {
      _finishSyncIfCurrent(extractionToken);
      return false;
    }

    if (state.messages.length != messageSnapshot.length) {
      _finishSyncIfCurrent(extractionToken);
      return false;
    }

    for (int i = 0; i < messageSnapshot.length; i++) {
      final current = state.messages[i];
      final snapshot = messageSnapshot[i];
      if (current.content != snapshot.content ||
          current.isUser != snapshot.isUser ||
          current.timestamp != snapshot.timestamp) {
        _finishSyncIfCurrent(extractionToken);
        return false;
      }
    }

    return true;
  }

  void _finishSyncIfCurrent(int extractionToken) {
    if (_latestExtractionToken == extractionToken && state.isSyncing) {
      state = state.copyWith(isSyncing: false);
    }
  }
}
