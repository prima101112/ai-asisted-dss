# AI Provider Abstraction Design

**Date:** 2025-04-10  
**Author:** Prima Adi, Ade Dwi  
**Status:** Approved  

---

## 1. Overview

This design introduces an abstraction layer for AI providers in the Smart DSS AI Assistant app. Currently, the app uses DeepSeek AI exclusively. This enhancement adds **Kimi AI as the primary provider** with **DeepSeek as a fallback**, using the Strategy Pattern for clean architecture.

### Goals
- Make AI provider swappable without changing business logic
- Support Kimi (primary) and DeepSeek (fallback) based on `.env` configuration
- Maintain backward compatibility with existing DeepSeek integration
- Enable easy addition of future AI providers

---

## 2. Architecture

### 2.1 Pattern: Strategy Pattern

We use the Strategy Pattern to encapsulate AI provider behavior behind a common interface. This allows the app to:
- Switch providers at startup based on configuration
- Add new providers without modifying existing code (Open/Closed Principle)
- Test business logic with mock providers

### 2.2 Provider Selection Priority

```
1. Check for KIMI_API_KEY in .env
   └── If present and non-empty → Use KimiProvider (PRIMARY)

2. Check for DEEPSEEK_API_KEY in .env  
   └── If present and non-empty → Use DeepSeekProvider (FALLBACK)

3. Neither key present
   └── Return null / Throw exception → Show user error
```

### 2.3 File Structure

```
lib/services/
├── ai_provider.dart              # Abstract interface (NEW)
├── kimi_provider.dart            # Kimi implementation (NEW)
├── deepseek_provider.dart        # Refactored DeepSeek (MODIFY)
└── ai_provider_factory.dart      # Factory with priority logic (NEW)
```

---

## 3. Component Specifications

### 3.1 AIProvider Interface

**File:** `lib/services/ai_provider.dart`

```dart
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

**Design Notes:**
- All methods match current DeepSeekService API for easy migration
- Uses same model types (`DecisionSession`, etc.)
- Async by design - all AI calls are network-based

### 3.2 KimiProvider

**File:** `lib/services/kimi_provider.dart`

**API Configuration:**
- **Base URL:** `https://api.kimi.com/coding/v1`
- **Endpoint:** `/chat/completions`
- **Model:** `kimi-for-coding`
- **Headers:**
  ```
  Content-Type: application/json
  Authorization: Bearer $KIMI_API_KEY
  User-Agent: KimiCLI/1.3
  ```

**Implementation Details:**
- Uses Dio HTTP client (same as DeepSeek)
- Same system prompts work for Kimi
- Same temperature (0.3) for consistent results
- Same JSON extraction logic

**System Prompts:**
Reuse existing prompts from DeepSeek:
- `chatSystemPrompt` - DSS guide for data gathering
- `calculationAnalysisSystemPrompt` - Result analysis
- Extraction prompt for structured data

### 3.3 DeepSeekProvider

**File:** `lib/services/deepseek_provider.dart`

**Changes from Current Implementation:**
- Extract from `deepseek_service.dart` into new file
- Implement `AIProvider` interface
- Add constructor parameter for API key instead of reading from dotenv internally
- Remove static constants, make them instance-based
- Keep all existing logic: prompts, data formatting, error handling

**API Configuration:**
- **Base URL:** `https://api.deepseek.com/v1`
- **Endpoint:** `/chat/completions`
- **Model:** `deepseek-chat`

### 3.4 AIProviderFactory

**File:** `lib/services/ai_provider_factory.dart`

```dart
class AIProviderFactory {
  static AIProvider? createProvider() {
    // Primary: Kimi
    final kimiKey = dotenv.env['KIMI_API_KEY'];
    if (kimiKey != null && kimiKey.isNotEmpty && kimiKey != 'your_kimi_key_here') {
      debugPrint('--- Using Kimi AI Provider (Primary) ---');
      return KimiProvider(apiKey: kimiKey);
    }
    
    // Fallback: DeepSeek
    final deepseekKey = dotenv.env['DEEPSEEK_API_KEY'];
    if (deepseekKey != null && deepseekKey.isNotEmpty && deepseekKey != 'your_api_key_here') {
      debugPrint('--- Using DeepSeek AI Provider (Fallback) ---');
      return DeepSeekProvider(apiKey: deepseekKey);
    }
    
    // No provider available
    debugPrint('--- ERROR: No AI provider configured ---');
    return null;
  }
  
  /// Helper to check if any provider is available
  static bool hasConfiguredProvider() {
    return createProvider() != null;
  }
}
```

**Design Notes:**
- Static factory method for simple usage
- Checks for placeholder values to avoid using dummy keys
- Returns null instead of throwing - lets caller decide how to handle
- Logging for debugging provider selection

---

## 4. Integration Points

### 4.1 ChatProvider

**Current:** Directly instantiates `DeepSeekService`

**New:** Uses `AIProviderFactory.createProvider()`

```dart
class ChatProvider extends StateNotifier<ChatState> {
  AIProvider? _aiProvider;
  
  ChatProvider() : super(ChatState.initial()) {
    _initializeProvider();
  }
  
  void _initializeProvider() {
    _aiProvider = AIProviderFactory.createProvider();
    if (_aiProvider == null) {
      // Handle error state - no AI provider
    }
  }
  
  // Use _aiProvider?.getChatResponse() instead of DeepSeekService
}
```

### 4.2 Environment Variables

**Update `.env` file:**

```env
# Primary AI Provider (Kimi)
KIMI_API_KEY=your_kimi_key_here

# Fallback AI Provider (DeepSeek) - optional
DEEPSEEK_API_KEY=your_deepseek_key_here
```

**pubspec.yaml:** Ensure `.env` is in assets (already done)

### 4.3 Error Handling

**Provider Not Available:**
- Show user-friendly error: "No AI provider configured. Please check your settings."
- Log detailed error for debugging

**API Errors:**
- Kimi/DeepSeek specific errors bubble up through interface
- Same error handling pattern as current implementation

**Fallback Behavior:**
- Only check at startup - no runtime switching
- If Kimi fails during session, don't auto-switch (user should restart app)
- This keeps implementation simple

---

## 5. Data Flow

### 5.1 Initialization Flow

```
App Startup
    ↓
ChatProvider initialized
    ↓
AIProviderFactory.createProvider() called
    ↓
Check KIMI_API_KEY → Exists?
    ├── Yes → Return KimiProvider
    └── No → Check DEEPSEEK_API_KEY → Exists?
            ├── Yes → Return DeepSeekProvider
            └── No → Return null
    ↓
Provider stored in ChatProvider
```

### 5.2 Chat Request Flow

```
User sends message
    ↓
ChatProvider.addMessage()
    ↓
_aiProvider.getChatResponse(messages, session, languageCode)
    ↓
Provider-specific HTTP request
    ↓
Response returned
    ↓
UI updated with AI response
```

### 5.3 Calculation Analysis Flow

```
User requests calculation
    ↓
DSS Engine calculates locally
    ↓
_aiProvider.getCalculationAnalysis(session, languageCode)
    ↓
Provider explains results based on local calculation
    ↓
UI shows explanation
```

---

## 6. Testing Strategy

### 6.1 Unit Tests
- Test `AIProviderFactory` with various `.env` configurations
- Mock `AIProvider` interface for testing ChatProvider logic

### 6.2 Integration Tests
- Test actual HTTP calls with test API keys
- Verify JSON extraction works with real responses

### 6.3 Provider-Specific Tests
- Same test suite should pass for both Kimi and DeepSeek
- Only difference is API key used

---

## 7. Migration Plan

### Phase 1: Create Interface (No breaking changes)
1. Create `ai_provider.dart` with abstract interface
2. Create `kimi_provider.dart` implementing interface
3. Test Kimi provider independently

### Phase 2: Refactor DeepSeek (No breaking changes)
1. Create `deepseek_provider.dart` from existing code
2. Refactor to implement `AIProvider` interface
3. Keep `deepseek_service.dart` as deprecated wrapper during transition

### Phase 3: Integration (Breaking change - internal only)
1. Create `ai_provider_factory.dart`
2. Update `ChatProvider` to use factory
3. Remove deprecated `deepseek_service.dart`
4. Update `.env` template

### Phase 4: Verification
1. Test with Kimi key only (should use Kimi)
2. Test with DeepSeek key only (should use DeepSeek)
3. Test with both keys (should use Kimi - primary)
4. Test with no keys (should show error)

---

## 8. Future Considerations

### 8.1 Adding More Providers
To add a new provider (e.g., OpenAI, Claude):
1. Create `openai_provider.dart` implementing `AIProvider`
2. Update factory priority logic
3. Add new `.env` key check

### 8.2 Runtime Provider Switching
If needed later:
- Make `ChatProvider` reactive to settings changes
- Add UI toggle in settings screen
- Store preference in SharedPreferences

### 8.3 Provider-Specific Features
If Kimi/DeepSeek have unique features:
- Add optional methods to interface with default no-op
- Or use extension methods for provider-specific capabilities

---

## 9. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Kimi API behaves differently | High | Test thoroughly with real API calls, adjust prompts if needed |
| Factory returns null | Medium | Add clear error UI, validate `.env` on startup |
| Breaking existing DeepSeek | High | Keep backward compatibility, test all existing flows |
| Performance difference | Low | Both use Dio, similar latency expected |

---

## 10. Success Criteria

- [ ] Kimi works as primary when `KIMI_API_KEY` is set
- [ ] DeepSeek works as fallback when only `DEEPSEEK_API_KEY` is set
- [ ] App shows error when no keys are configured
- [ ] All existing DeepSeek functionality preserved
- [ ] Chat, calculation analysis, and data extraction work with both providers
- [ ] Code follows Strategy Pattern, easy to extend

---

**Next Step:** Create implementation plan using `writing-plans` skill.
