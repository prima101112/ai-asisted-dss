import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.deepseek.com/v1';

  String get _apiKey {
    final key = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
    debugPrint("--- API Key Check: ${key.isNotEmpty ? 'Found' : 'EMPTY'} ---");
    return key;
  }

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

  Future<String> getChatResponse(List<Map<String, String>> messages) async {
    // Prepend the personality/guide prompt for normal chat
    final List<Map<String, String>> fullMessages = [
      {'role': 'system', 'content': chatSystemPrompt},
      ...messages,
    ];
    return _makeRawRequest(fullMessages);
  }

  /// This method asks the AI to extract structured data from the conversation
  Future<Map<String, dynamic>?> extractStructuredData(
    List<Map<String, String>> conversationHistory,
  ) async {
    const extractionPrompt = '''
You are a data extraction tool for a DSS. Analyze the chat and extract the **TOTAL CURRENT STATE** of the decision components into JSON.
JSON Structure:
{
  "title": string | null,
  "criteria": [ { "name": string, "type": "benefit" | "cost", "weight": number } ],
  "alternatives": [ { "name": string, "scores": { "criterion_name": number } } ],
  "status": "gathering" | "ready" | "calculated"
}
Rules:
- You MUST return EVERY criterion and alternative ever mentioned in the chat history. 
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
}
