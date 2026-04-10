import 'dart:async';

import 'package:ai_assisted_dss/models/alternative.dart';
import 'package:ai_assisted_dss/models/criterion.dart';
import 'package:ai_assisted_dss/models/decision_session.dart';
import 'package:ai_assisted_dss/logic/dss_engine.dart';
import 'package:ai_assisted_dss/providers/chat_provider.dart';
import 'package:ai_assisted_dss/services/deepseek_service.dart';
import 'package:ai_assisted_dss/services/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeepSeekService extends DeepSeekService {
  int chatCalls = 0;
  int extractCalls = 0;
  int analysisCalls = 0;

  Completer<String>? pendingChatResponse;
  String chatResponse = 'Assistant reply';
  String analysisResponse = 'Local analysis';
  Map<String, dynamic>? extractedData;
  DecisionSession? analysisSession;

  @override
  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? languageCode,
    DecisionSession? session,
  }) async {
    chatCalls++;
    if (pendingChatResponse != null) {
      return pendingChatResponse!.future;
    }
    return chatResponse;
  }

  @override
  Future<Map<String, dynamic>?> extractStructuredData(
    List<Map<String, String>> conversationHistory, {
    DecisionSession? session,
  }) async {
    extractCalls++;
    return extractedData;
  }

  @override
  Future<String> getCalculationAnalysis(
    DecisionSession session, {
    String? languageCode,
  }) async {
    analysisCalls++;
    analysisSession = session;
    return analysisResponse;
  }
}

class FakeFirebaseService extends FirebaseService {
  final List<DecisionSession> savedSessions = [];

  @override
  Future<void> saveSession(DecisionSession session) async {
    savedSessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async {}
}

void main() {
  group('ChatNotifier', () {
    late FakeDeepSeekService aiService;
    late FakeFirebaseService firebaseService;
    late ChatNotifier notifier;

    setUp(() {
      aiService = FakeDeepSeekService();
      firebaseService = FakeFirebaseService();
      notifier = ChatNotifier(aiService, firebaseService);
    });

    test('blocks overlapping chat requests while loading', () async {
      aiService.pendingChatResponse = Completer<String>();
      aiService.extractedData = {
        'title': null,
        'criteria': [],
        'alternatives': [],
      };

      final firstRequest = notifier.sendMessage('First message');
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isTrue);

      await notifier.sendMessage('Second message');

      expect(aiService.chatCalls, 1);
      expect(
        notifier.state.messages.where((message) => message.isUser).length,
        1,
      );

      aiService.pendingChatResponse!.complete('Assistant reply');
      await firstRequest;

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.messages.last.content, 'Assistant reply');
    });

    test('does not calculate when decision data is incomplete', () async {
      notifier.startFromHistory(
        DecisionSession(
          id: 'history-1',
          title: 'Choose Laptop',
          criteria: [
            Criterion(
              id: 'price',
              name: 'Price',
              weight: 0.5,
              type: CriterionType.cost,
            ),
            Criterion(
              id: 'battery',
              name: 'Battery',
              weight: 0.5,
              type: CriterionType.benefit,
            ),
          ],
          alternatives: [
            Alternative(id: 'a', name: 'Laptop A', scores: const {'price': 10}),
          ],
          createdAt: DateTime(2026),
        ),
      );

      final didCalculate = await notifier.calculateRanking(
        DSSMethod.saw,
        languageCode: 'en',
      );

      expect(didCalculate, isFalse);
      expect(notifier.state.session!.status, 'gathering');
      expect(
        notifier.state.messages.last.content,
        contains('decision data is incomplete'),
      );
    });

    test('uses local ranking results as the basis for AI analysis', () async {
      notifier.startFromHistory(
        DecisionSession(
          id: 'history-2',
          title: 'Choose Laptop',
          criteria: [
            Criterion(
              id: 'price',
              name: 'Price',
              weight: 0.6,
              type: CriterionType.cost,
            ),
            Criterion(
              id: 'battery',
              name: 'Battery',
              weight: 0.4,
              type: CriterionType.benefit,
            ),
          ],
          alternatives: [
            Alternative(
              id: 'a',
              name: 'Laptop A',
              scores: const {'price': 8, 'battery': 9},
            ),
            Alternative(
              id: 'b',
              name: 'Laptop B',
              scores: const {'price': 12, 'battery': 7},
            ),
          ],
          createdAt: DateTime(2026),
        ),
      );

      await notifier.calculateRankingAndAnalyze(
        DSSMethod.saw,
        languageCode: 'en',
      );

      expect(aiService.analysisCalls, 1);
      expect(aiService.analysisSession, isNotNull);
      expect(aiService.analysisSession!.results, isNotEmpty);
      expect(
        aiService.analysisSession!.results!.first.alternativeName,
        notifier.state.session!.results!.first.alternativeName,
      );
      expect(notifier.state.messages.last.content, 'Local analysis');
    });

    test('calculates AHP rankings and exposes audit matrices', () {
      final result = DSSEngine.calculate(
        [
          Criterion(
            id: 'price',
            name: 'Price',
            weight: 0.6,
            type: CriterionType.cost,
          ),
          Criterion(
            id: 'battery',
            name: 'Battery',
            weight: 0.4,
            type: CriterionType.benefit,
          ),
        ],
        [
          Alternative(
            id: 'a',
            name: 'Laptop A',
            scores: const {'price': 8, 'battery': 9},
          ),
          Alternative(
            id: 'b',
            name: 'Laptop B',
            scores: const {'price': 12, 'battery': 7},
          ),
        ],
        DSSMethod.ahp,
      );

      expect(result.rankings, isNotEmpty);
      expect(result.rankings.first.alternativeName, 'Laptop A');
      expect(result.matrices['Criteria Pairwise Matrix'], isNotNull);
      expect(result.matrices['Criteria Priority Vector'], isNotNull);
      expect(result.matrices['Battery Local Priority'], isNotNull);
    });

    test(
      'recalculates locally when chat requests analysis with a different method',
      () async {
        notifier.startFromHistory(
          DecisionSession(
            id: 'history-2b',
            title: 'Choose Laptop',
            criteria: [
              Criterion(
                id: 'price',
                name: 'Price',
                weight: 0.6,
                type: CriterionType.cost,
              ),
              Criterion(
                id: 'battery',
                name: 'Battery',
                weight: 0.4,
                type: CriterionType.benefit,
              ),
            ],
            alternatives: [
              Alternative(
                id: 'a',
                name: 'Laptop A',
                scores: const {'price': 8, 'battery': 9},
              ),
              Alternative(
                id: 'b',
                name: 'Laptop B',
                scores: const {'price': 12, 'battery': 7},
              ),
            ],
            createdAt: DateTime(2026),
          ),
        );

        await notifier.calculateRanking(DSSMethod.saw, languageCode: 'id');
        expect(notifier.state.session!.selectedMethod, DSSMethod.saw);

        await notifier.sendMessage(
          'Jelaskan hasil ini dengan metode TOPSIS',
          languageCode: 'id',
        );

        expect(aiService.chatCalls, 0);
        expect(aiService.analysisCalls, 1);
        expect(notifier.state.session!.selectedMethod, DSSMethod.topsis);
        expect(aiService.analysisSession!.selectedMethod, DSSMethod.topsis);
        expect(notifier.state.messages.last.content, 'Local analysis');
      },
    );

    test('routes AHP chat requests to local AHP analysis', () async {
      notifier.startFromHistory(
        DecisionSession(
          id: 'history-ahp',
          title: 'Choose Laptop',
          criteria: [
            Criterion(
              id: 'price',
              name: 'Price',
              weight: 0.6,
              type: CriterionType.cost,
            ),
            Criterion(
              id: 'battery',
              name: 'Battery',
              weight: 0.4,
              type: CriterionType.benefit,
            ),
          ],
          alternatives: [
            Alternative(
              id: 'a',
              name: 'Laptop A',
              scores: const {'price': 8, 'battery': 9},
            ),
            Alternative(
              id: 'b',
              name: 'Laptop B',
              scores: const {'price': 12, 'battery': 7},
            ),
          ],
          createdAt: DateTime(2026),
        ),
      );

      await notifier.sendMessage(
        'Tolong jelaskan hasil ini dengan metode AHP',
        languageCode: 'id',
      );

      expect(aiService.chatCalls, 0);
      expect(aiService.analysisCalls, 1);
      expect(notifier.state.session!.selectedMethod, DSSMethod.ahp);
      expect(aiService.analysisSession!.selectedMethod, DSSMethod.ahp);
    });

    test('clears stale results when extracted decision data changes', () async {
      notifier.startFromHistory(
        DecisionSession(
          id: 'history-3',
          title: 'Choose Laptop',
          criteria: [
            Criterion(
              id: 'price',
              name: 'Price',
              weight: 1,
              type: CriterionType.cost,
            ),
          ],
          alternatives: [
            Alternative(id: 'a', name: 'Laptop A', scores: const {'price': 10}),
            Alternative(id: 'b', name: 'Laptop B', scores: const {'price': 20}),
          ],
          createdAt: DateTime(2026),
        ),
      );

      await notifier.calculateRanking(DSSMethod.saw, languageCode: 'en');

      aiService.chatResponse = 'Please add battery life too.';
      aiService.extractedData = {
        'title': 'Choose Laptop',
        'criteria': [
          {'name': 'Price', 'type': 'cost', 'weight': 0.5},
          {'name': 'Battery', 'type': 'benefit', 'weight': 0.5},
        ],
        'alternatives': [
          {
            'name': 'Laptop A',
            'scores': {'Price': 10},
          },
          {
            'name': 'Laptop B',
            'scores': {'Price': 20},
          },
        ],
      };

      await notifier.sendMessage('Add battery life as a criterion');
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.session!.results, isNull);
      expect(notifier.state.session!.selectedMethod, isNull);
      expect(notifier.state.session!.status, 'gathering');
    });
  });
}
