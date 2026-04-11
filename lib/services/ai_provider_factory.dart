import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';
import 'kimi_provider.dart';
import 'deepseek_provider.dart';

class AIProviderFactory {
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

    debugPrint('--- ERROR: No AI provider configured ---');
    return null;
  }

  static bool hasConfiguredProvider() => createProvider() != null;

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
