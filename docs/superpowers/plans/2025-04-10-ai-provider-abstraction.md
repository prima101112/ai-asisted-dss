# AI Provider Abstraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Kimi AI as primary provider with DeepSeek fallback using Strategy Pattern

**Architecture:** Create abstract `AIProvider` interface, implement `KimiProvider` and `DeepSeekProvider`, use factory for selection. No tests - smoke test in emulator after completion.

**Tech Stack:** Flutter, Dart, Dio, flutter_dotenv, flutter_riverpod

---

## File Structure

```
lib/services/
├── ai_provider.dart              # NEW - Abstract interface
├── kimi_provider.dart            # NEW - Kimi implementation
├── deepseek_provider.dart        # NEW - Refactored DeepSeek
├── ai_provider_factory.dart      # NEW - Factory with priority logic
└── deepseek_service.dart         # DELETE - After migration
```

---

## Task 1: Create AIProvider Abstract Interface

**Files:**
- Create: `lib/services/ai_provider.dart`

**Purpose:** Define the contract all AI providers must implement

- [ ] **Step 1: Create abstract interface**

```dart
import '../models/decision_session.dart';

/// Abstract interface for AI providers (DeepSeek, Kimi, etc.)
abstract class AIProvider {
  /// Provider name for logging/debugging
  String get providerName;

  /// Get conversational response for chat UI
  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? languageCode,
    DecisionSession? session,
  });

  /// Get analysis of calculation results
  Future<String> getCalculationAnalysis(
    DecisionSession session, {
    String? languageCode,
  });

  /// Extract structured data from conversation
  Future<Map<String, dynamic>?> extractStructuredData(
    List<Map<String, String>> conversationHistory, {
    DecisionSession? session,
  });
}
```

- [ ] **Step 2: Verify file created**

Run: `ls -la lib/services/ai_provider.dart`
Expected: File exists

---

## Task 2: Create KimiProvider Implementation

**Files:**
- Create: `lib/services/kimi_provider.dart`

**Purpose:** Implement Kimi AI provider with kimi-for-coding model

- [ ] **Step 1: Create KimiProvider class**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';
import '../models/decision_session.dart';

class KimiProvider implements AIProvider {
  final Dio _dio = Dio();
  final String _apiKey;
  final String _baseUrl = 'https://api.kimi.com/coding/v1';
  static const String _missingTitleLabel = '(not provided yet)';

  KimiProvider({required String apiKey}) : _apiKey = apiKey;

  @override
  String get providerName => 'Kimi';

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
      debugPrint("--- AI Request to \$_baseUrl (Kimi) ---");
      final response = await _dio.post(
        '\$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer \$_apiKey',
            'Content-Type': 'application/json',
            'User-Agent': 'KimiCLI/1.3',
          },
        ),
        data: {
          'model': 'kimi-for-coding',
          'messages': messages,
          'temperature': 0.3,
        },
      );
      return response.data['choices'][0]['message']['content'];
    } on DioException catch (e) {
      debugPrint('Dio error (Kimi): \${e.response?.data}');
      throw Exception('AI Error (Kimi): \${e.message}');
    } catch (e) {
      throw Exception('Failed to connect to Kimi: \$e');
    }
  }

  @override
  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? languageCode,
    DecisionSession? session,
  }) async {
    String systemPrompt = chatSystemPrompt;

    if (session != null) {
      systemPrompt += _buildCurrentStatePrompt(session);
    }

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
          "\\nKNOWN CURRENT STATE (Base off this if discussion is minimal):\\n\${_buildCurrentStatePrompt(session)}\\n";
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
      final String jsonStr = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      debugPrint("--- Raw AI Data Extract (Kimi): \$jsonStr ---");
      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('Extraction error (Kimi): \$e');
      return null;
    }
  }

  String _buildCurrentStatePrompt(DecisionSession session) {
    String prompt = "\\n\\nCURRENT LOADED DECISION DATA:\\n";
    prompt += "Title: \${_displayTitle(session.title)}\\n";

    if (session.criteria.isNotEmpty) {
      prompt += "Criteria:\\n";
      for (var c in session.criteria) {
        prompt += "- \${c.name} (\${c.type.name}, weight: \${c.weight})\\n";
      }
    }

    if (session.alternatives.isNotEmpty) {
      prompt += "Alternatives:\\n";
      for (var a in session.alternatives) {
        prompt +=
            "- \${a.name} (Scores: \${_formatScoresWithCriterionNames(session, a.scores)})\\n";
      }
    }

    if (session.results != null && session.results!.isNotEmpty) {
      if (session.selectedMethod != null) {
        prompt +=
            "\\nCURRENT SELECTED CALCULATION METHOD: \${session.selectedMethod!.name.toUpperCase()}\\n";
      }
      prompt += "\\nFINAL CALCULATION RESULTS (Use these for your analysis):\\n";
      for (var r in session.results!) {
        prompt +=
            "- Rank #\${r.rank}: \${r.alternativeName} (Total Final Score: \${r.score.toStringAsFixed(4)})\\n";
      }
    }

    prompt +=
        "\\nNote: ALWAYS prioritize the 'FINAL CALCULATION RESULTS' above for your analysis. Do not calculate manually. If the user asks about a different method than the current selected method, do not pretend the current ranking belongs to that other method. Explain the winners based on how their individual criteria scores (listed under Alternatives) align with the criterion weights.";
    return prompt;
  }

  String _buildLanguageInstruction(String? languageCode) {
    if (languageCode == 'id') {
      return "\\n\\nIMPORTANT: You MUST reply in INDONESIAN language.";
    }
    return "\\n\\nIMPORTANT: You MUST reply in ENGLISH language.";
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
      return '\$criterionName: \${entry.value}';
    }).toList()..sort();

    return '{\${formattedEntries.join(', ')}}';
  }
}
```

- [ ] **Step 2: Verify file created**

Run: `head -20 lib/services/kimi_provider.dart`
Expected: Shows import statements and class declaration

---

## Task 3: Create DeepSeekProvider (Refactored)

**Files:**
- Create: `lib/services/deepseek_provider.dart`

**Purpose:** Refactor existing DeepSeek logic into AIProvider implementation

- [ ] **Step 1: Create DeepSeekProvider class**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';
import '../models/decision_session.dart';

class DeepSeekProvider implements AIProvider {
  final Dio _dio = Dio();
  final String _apiKey;
  final String _baseUrl = 'https://api.deepseek.com/v1';
  static const String _missingTitleLabel = '(not provided yet)';

  DeepSeekProvider({required String apiKey}) : _apiKey = apiKey;

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
      debugPrint("--- AI Request to \$_baseUrl (DeepSeek) ---");
      final response = await _dio.post(
        '\$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer \$_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.3,
        },
      );
      return response.data['choices'][0]['message']['content'];
    } on DioException catch (e) {
      debugPrint('Dio error (DeepSeek): \${e.response?.data}');
      throw Exception('AI Error (DeepSeek): \${e.message}');
    } catch (e) {
      throw Exception('Failed to connect to DeepSeek: \$e');
    }
  }

  @override
  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? languageCode,
    DecisionSession? session,
  }) async {
    String systemPrompt = chatSystemPrompt;

    if (session != null) {
      systemPrompt += _buildCurrentStatePrompt(session);
    }

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
          "\\nKNOWN CURRENT STATE (Base off this if discussion is minimal):\\n\${_buildCurrentStatePrompt(session)}\\n";
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
      final String jsonStr = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      debugPrint("--- Raw AI Data Extract (DeepSeek): \$jsonStr ---");
      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('Extraction error (DeepSeek): \$e');
      return null;
    }
  }

  String _buildCurrentStatePrompt(DecisionSession session) {
    String prompt = "\\n\\nCURRENT LOADED DECISION DATA:\\n";
    prompt += "Title: \${_displayTitle(session.title)}\\n";

    if (session.criteria.isNotEmpty) {
      prompt += "Criteria:\\n";
      for (var c in session.criteria) {
        prompt += "- \${c.name} (\${c.type.name}, weight: \${c.weight})\\n";
      }
    }

    if (session.alternatives.isNotEmpty) {
      prompt += "Alternatives:\\n";
      for (var a in session.alternatives) {
        prompt +=
            "- \${a.name} (Scores: \${_formatScoresWithCriterionNames(session, a.scores)})\\n";
      }
    }

    if (session.results != null && session.results!.isNotEmpty) {
      if (session.selectedMethod != null) {
        prompt +=
            "\\nCURRENT SELECTED CALCULATION METHOD: \${session.selectedMethod!.name.toUpperCase()}\\n";
      }
      prompt += "\\nFINAL CALCULATION RESULTS (Use these for your analysis):\\n";
      for (var r in session.results!) {
        prompt +=
            "- Rank #\${r.rank}: \${r.alternativeName} (Total Final Score: \${r.score.toStringAsFixed(4)})\\n";
      }
    }

    prompt +=
        "\\nNote: ALWAYS prioritize the 'FINAL CALCULATION RESULTS' above for your analysis. Do not calculate manually. If the user asks about a different method than the current selected method, do not pretend the current ranking belongs to that other method. Explain the winners based on how their individual criteria scores (listed under Alternatives) align with the criterion weights.";
    return prompt;
  }

  String _buildLanguageInstruction(String? languageCode) {
    if (languageCode == 'id') {
      return "\\n\\nIMPORTANT: You MUST reply in INDONESIAN language.";
    }
    return "\\n\\nIMPORTANT: You MUST reply in ENGLISH language.";
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
      return '\$criterionName: \${entry.value}';
    }).toList()..sort();

    return '{\${formattedEntries.join(', ')}}';
  }
}
```

- [ ] **Step 2: Verify file created**

Run: `head -20 lib/services/deepseek_provider.dart`
Expected: Shows import statements and class declaration

---

## Task 4: Create AIProviderFactory

**Files:**
- Create: `lib/services/ai_provider_factory.dart`

**Purpose:** Factory that selects provider based on .env configuration (Kimi primary, DeepSeek fallback)

- [ ] **Step 1: Create factory class**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';
import 'kimi_provider.dart';
import 'deepseek_provider.dart';

/// Factory for creating AI provider instances
/// Priority: Kimi (primary) -> DeepSeek (fallback)
class AIProviderFactory {
  /// Creates an AI provider based on environment configuration
  /// 
  /// Priority order:
  /// 1. Kimi - if KIMI_API_KEY is set
  /// 2. DeepSeek - if DEEPSEEK_API_KEY is set
  /// 3. null - if no keys are configured
  static AIProvider? createProvider() {
    // Primary: Kimi
    final kimiKey = dotenv.env['KIMI_API_KEY'];
    if (kimiKey != null &&
        kimiKey.isNotEmpty &&
        !kimiKey.contains('your_kimi_key')) {
      debugPrint('--- Using Kimi AI Provider (Primary) ---');
      return KimiProvider(apiKey: kimiKey);
    }

    // Fallback: DeepSeek
    final deepseekKey = dotenv.env['DEEPSEEK_API_KEY'];
    if (deepseekKey != null &&
        deepseekKey.isNotEmpty &&
        !deepseekKey.contains('your_api_key')) {
      debugPrint('--- Using DeepSeek AI Provider (Fallback) ---');
      return DeepSeekProvider(apiKey: deepseekKey);
    }

    // No provider available
    debugPrint('--- ERROR: No AI provider configured ---');
    debugPrint('--- Please set KIMI_API_KEY or DEEPSEEK_API_KEY in .env ---');
    return null;
  }

  /// Checks if any AI provider is configured
  static bool hasConfiguredProvider() {
    return createProvider() != null;
  }

  /// Gets the name of the provider that would be selected
  static String getSelectedProviderName() {
    final kimiKey = dotenv.env['KIMI_API_KEY'];
    if (kimiKey != null &&
        kimiKey.isNotEmpty &&
        !kimiKey.contains('your_kimi_key')) {
      return 'Kimi';
    }

    final deepseekKey = dotenv.env['DEEPSEEK_API_KEY'];
    if (deepseekKey != null &&
        deepseekKey.isNotEmpty &&
        !deepseekKey.contains('your_api_key')) {
      return 'DeepSeek';
    }

    return 'None';
  }
}
```

- [ ] **Step 2: Verify file created**

Run: `head -30 lib/services/ai_provider_factory.dart`
Expected: Shows factory class with createProvider method

---

## Task 5: Update ChatProvider to Use Factory

**Files:**
- Read: `lib/providers/chat_provider.dart` (to understand current structure)
- Modify: `lib/providers/chat_provider.dart`

**Purpose:** Replace direct DeepSeekService usage with AIProviderFactory

- [ ] **Step 1: Read current ChatProvider**

Run: `cat lib/providers/chat_provider.dart`
Expected: See current implementation with DeepSeekService usage

- [ ] **Step 2: Modify imports**

Replace:
```dart
import '../services/deepseek_service.dart';
```

With:
```dart
import '../services/ai_provider.dart';
import '../services/ai_provider_factory.dart';
```

- [ ] **Step 3: Replace DeepSeekService field**

Replace:
```dart
final DeepSeekService _aiService = DeepSeekService();
```

With:
```dart
AIProvider? _aiProvider;
```

- [ ] **Step 4: Add initialization in constructor**

Add in constructor body:
```dart
_aiProvider = AIProviderFactory.createProvider();
if (_aiProvider == null) {
  // Handle error - no AI provider configured
  state = state.copyWith(
    errorMessage: 'No AI provider configured. Please check your .env file.',
  );
}
```

- [ ] **Step 5: Replace all _aiService calls with _aiProvider**

Replace:
```dart
await _aiService.getChatResponse(...)
```

With:
```dart
await _aiProvider?.getChatResponse(...)
```

Do this for all three methods:
- `getChatResponse`
- `getCalculationAnalysis`
- `extractStructuredData`

- [ ] **Step 6: Add null checks before AI calls**

Before each AI call, check:
```dart
if (_aiProvider == null) {
  state = state.copyWith(
    errorMessage: 'AI provider not available',
  );
  return;
}
```

---

## Task 6: Update .env Template

**Files:**
- Modify: `.env`

**Purpose:** Add KIMI_API_KEY placeholder

- [ ] **Step 1: Update .env file**

```env
# Primary AI Provider (Kimi)
KIMI_API_KEY=your_kimi_key_here

# Fallback AI Provider (DeepSeek) - optional
DEEPSEEK_API_KEY=sk-cd990b636af14828bcdbe6bf24a0d37c
```

---

## Task 7: Verify Compilation

**Files:**
- All modified files

**Purpose:** Ensure no syntax errors before smoke test

- [ ] **Step 1: Run Flutter analyze**

Run: `flutter analyze`
Expected: No errors in lib/services/ files

- [ ] **Step 2: Check for missing imports**

Run: `flutter pub get`
Expected: Dependencies resolved

---

## Task 8: Clean Up (Optional - After Verification)

**Files:**
- Delete: `lib/services/deepseek_service.dart`

**Purpose:** Remove old file after confirming everything works

- [ ] **Step 1: Delete old file**

Run: `rm lib/services/deepseek_service.dart`

- [ ] **Step 2: Verify no references remain**

Run: `grep -r "DeepSeekService" lib/`
Expected: No results (or only in comments)

---

## Smoke Test Checklist (Manual)

After implementation, test in emulator:

- [ ] **Test 1: Kimi Primary**
  - Set `KIMI_API_KEY` to valid key
  - Start app
  - Send a chat message
  - Check logs show "Using Kimi AI Provider (Primary)"
  - Verify AI responds correctly

- [ ] **Test 2: DeepSeek Fallback**
  - Remove/comment out `KIMI_API_KEY`
  - Keep `DEEPSEEK_API_KEY`
  - Restart app
  - Send a chat message
  - Check logs show "Using DeepSeek AI Provider (Fallback)"
  - Verify AI responds correctly

- [ ] **Test 3: No Provider Error**
  - Remove both keys from .env
  - Restart app
  - Verify error message shows: "No AI provider configured"

- [ ] **Test 4: Calculation Analysis**
  - Complete a full decision flow
  - Request calculation (SAW/WP/AHP/TOPSIS)
  - Verify AI explains results correctly

- [ ] **Test 5: Data Extraction**
  - Chat about criteria and alternatives
  - Verify data is extracted and displayed in UI

---

## Notes for Implementer

1. **No Tests Required** - User will smoke test in emulator
2. **Preserve Existing Behavior** - All prompts and logic remain identical
3. **Error Messages** - Should clearly indicate which provider failed
4. **Logging** - Keep debugPrint statements for troubleshooting
5. **Backward Compatibility** - DeepSeek alone should still work as fallback

---

**Ready for implementation!** Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to execute these tasks.