import '../../domain/models/provider_account.dart';
import 'ai_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';
import 'openrouter_provider.dart';

/// Builds a concrete [AiProvider] from account metadata + raw API key.
class ProviderFactory {
  const ProviderFactory._();

  static AiProvider create(ProviderAccount account, String apiKey) {
    switch (account.providerType) {
      case ProviderType.openai:
        return OpenAiProvider(apiKey: apiKey);
      case ProviderType.openrouter:
        return OpenRouterProvider(apiKey: apiKey);
      case ProviderType.gemini:
        return GeminiProvider(apiKey: apiKey);
    }
  }
}
