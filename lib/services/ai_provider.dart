import '../models/decision_session.dart';

abstract class AIProvider {
  String get providerName;

  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? languageCode,
    DecisionSession? session,
  });

  Future<String> getCalculationAnalysis(
    DecisionSession session, {
    String? languageCode,
  });

  Future<Map<String, dynamic>?> extractStructuredData(
    List<Map<String, String>> conversationHistory, {
    DecisionSession? session,
  });
}
