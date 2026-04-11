import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/decision_session.dart';
import 'ai_provider.dart';

class DeepSeekProvider implements AIProvider {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.deepseek.com/v1';
  final String _apiKey;
  static const String _missingTitleLabel = '(not provided yet)';

  DeepSeekProvider({required String apiKey}) : _apiKey = apiKey {
    debugPrint(
      "--- DeepSeek API Key Check: ${_apiKey.isNotEmpty ? 'Found' : 'EMPTY'} ---",
    );
  }

  @override
  String get providerName => 'DeepSeek';

  static const String chatSystemPrompt = '''
You are a precise Decision Support System (DSS) Guide. Your goal is to gather data for a decision model. 
Use **Markdown formatting** to make your responses clear (e.g., use bold for headers, lists for options).

You MUST follow this exact sequence and ask only ONE thing at a time:
1. Ask for the **Decision Title** (what are we deciding?).
2. Ask for the **Criteria** one by one. For each criterion, ask for:
   - Name
   - Type (Benefit/Cost)
   - Weight (importance relative to others)
3. Ask for the **Alternatives** (the candidates/options).
4. Ask for the **Scores** of each Alternative for each Criterion.

**Rules:**
- Be concise. 
- Do not ask multiple questions at once.
- Once you have enough data for a step, move to the next.
- If the user provides multiple pieces of info, acknowledge and ask for the next missing piece.
- **IMPORTANT**: When the user asks for results or to perform a calculation, summarize the result with a **deep human-language analysis**.
- **DO NOT attempt to calculate the scores or ranks yourself**. Use ONLY the **Calculation Results (Rankings)** provided in the context.
- Your job is to **EXPLAIN** the ranking logic (how criteria influenced the result), not to perform the arithmetic.
- Focus on the **Top 3 choices** (or all if fewer than 3).
- Explain **WHY** they are ranked as such based on their performance in the most important criteria.
- Use a professional yet helpful tone.
- Tell the user they can see the full **Calculation Matrices** (normalization, weights, etc.) by clicking the **Analytics/Insights icon** (📈) in the top bar for technical verification.
''';

  static const String calculationAnalysisSystemPrompt = '''
You are a Decision Support System (DSS) result analyst.

You MUST explain the decision using ONLY the local calculation context provided to you.
- Never invent, modify, or recompute rankings, scores, or winners.
- Never replace the provided local results with your own answer.
- If local results are missing, say so briefly instead of guessing.
- Focus on explaining why the ranked alternatives performed that way based on the provided criteria, weights, and scores.
- Use Markdown formatting.
- Keep the explanation concise, practical, and grounded in the provided data.
''';

  Future<String> _makeRawRequest(List<Map<String, String>> messages) async {
    try {
      debugPrint("--- AI Request to $_baseUrl ---");
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.3, // Lower temperature for more consistent data
        },
      );
      return response.data['choices'][0]['message']['content'];
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.response?.data}');
      throw Exception('AI Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  @override
  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? languageCode,
    DecisionSession? session,
  }) async {
    // Prepend the personality/guide prompt for normal chat
    String systemPrompt = chatSystemPrompt;

    // Add current session context to system prompt
    if (session != null) {
      systemPrompt += _buildCurrentStatePrompt(session);
    }

    // Append language instruction
    systemPrompt += _buildLanguageInstruction(languageCode);

    final List<Map<String, String>> fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];
    return _makeRawRequest(fullMessages);
  }

  @override
  Future<String> getCalculationAnalysis(
    DecisionSession session, {
    String? languageCode,
  }) async {
    String systemPrompt = calculationAnalysisSystemPrompt;
    systemPrompt += _buildCurrentStatePrompt(session);
    systemPrompt += _buildLanguageInstruction(languageCode);

    final userPrompt = languageCode == 'id'
        ? 'Jelaskan hasil perhitungan lokal ini. Gunakan hanya ranking yang diberikan.'
        : 'Explain these local calculation results. Use only the provided ranking.';

    return _makeRawRequest([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ]);
  }

  /// This method asks the AI to extract structured data from the conversation
  @override
  Future<Map<String, dynamic>?> extractStructuredData(
    List<Map<String, String>> conversationHistory, {
    DecisionSession? session,
  }) async {
    String extractionPrompt = '''
You are a data extraction tool for a DSS. Analyze the chat and extract the **TOTAL CURRENT STATE** of the decision components into JSON.
''';

    if (session != null) {
      extractionPrompt +=
          "\nKNOWN CURRENT STATE (Base off this if discussion is minimal):\n${_buildCurrentStatePrompt(session)}\n";
    }

    extractionPrompt += '''
JSON Structure:
{
  "title": string | null,
  "criteria": [ { "name": string, "type": "benefit" | "cost", "weight": number } ],
  "alternatives": [ { "name": string, "scores": { "criterion_name": number } } ],
  "status": "gathering" | "ready" | "calculated"
}
Rules:
- You MUST return EVERY criterion and alternative ever mentioned in the chat history OR provided in the KNOWN CURRENT STATE. 
- Do not omit previous data just because you are discussing new data.
- status is "gathering" while info is missing, "ready" once title, criteria, alternatives, and scores are present.
- Return ONLY JSON.
''';

    final messages = [
      {'role': 'system', 'content': extractionPrompt},
      ...conversationHistory,
      {'role': 'user', 'content': 'Extract current state to JSON.'},
    ];

    try {
      final response = await _makeRawRequest(messages);
      // Clean the response if it contains markdown code blocks
      final String jsonStr = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      debugPrint("--- Raw AI Data Extract: $jsonStr ---");
      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('Extraction error: $e');
      return null;
    }
  }

  String _buildCurrentStatePrompt(DecisionSession session) {
    String prompt = "\n\nCURRENT LOADED DECISION DATA:\n";
    prompt += "Title: ${_displayTitle(session.title)}\n";

    if (session.criteria.isNotEmpty) {
      prompt += "Criteria:\n";
      for (var c in session.criteria) {
        prompt += "- ${c.name} (${c.type.name}, weight: ${c.weight})\n";
      }
    }

    if (session.alternatives.isNotEmpty) {
      prompt += "Alternatives:\n";
      for (var a in session.alternatives) {
        prompt +=
            "- ${a.name} (Scores: ${_formatScoresWithCriterionNames(session, a.scores)})\n";
      }
    }

    if (session.results != null && session.results!.isNotEmpty) {
      if (session.selectedMethod != null) {
        prompt +=
            "\nCURRENT SELECTED CALCULATION METHOD: ${session.selectedMethod!.name.toUpperCase()}\n";
      }
      prompt += "\nFINAL CALCULATION RESULTS (Use these for your analysis):\n";
      for (var r in session.results!) {
        prompt +=
            "- Rank #${r.rank}: ${r.alternativeName} (Total Final Score: ${r.score.toStringAsFixed(4)})\n";
      }
    }

    prompt +=
        "\nNote: ALWAYS prioritize the 'FINAL CALCULATION RESULTS' above for your analysis. Do not calculate manually. If the user asks about a different method than the current selected method, do not pretend the current ranking belongs to that other method. Explain the winners based on how their individual criteria scores (listed under Alternatives) align with the criterion weights.";
    return prompt;
  }

  String _buildLanguageInstruction(String? languageCode) {
    if (languageCode == 'id') {
      return "\n\nIMPORTANT: You MUST reply in INDONESIAN language.";
    }
    return "\n\nIMPORTANT: You MUST reply in ENGLISH language.";
  }

  String _displayTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isEmpty ? _missingTitleLabel : trimmed;
  }

  String _formatScoresWithCriterionNames(
    DecisionSession session,
    Map<String, double> scores,
  ) {
    if (scores.isEmpty) {
      return '{}';
    }

    final criterionNames = {
      for (final criterion in session.criteria) criterion.id: criterion.name,
    };

    final formattedEntries = scores.entries.map((entry) {
      final criterionName = criterionNames[entry.key] ?? entry.key;
      return '$criterionName: ${entry.value}';
    }).toList()..sort();

    return '{${formattedEntries.join(', ')}}';
  }
}
