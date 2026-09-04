import '../../domain/models/provider_account.dart';
import 'openai_compatible_provider.dart';

/// OpenRouter OpenAI-compatible API with app attribution headers.
class OpenRouterProvider extends OpenAiCompatibleProvider {
  OpenRouterProvider({
    required String apiKey,
    String? baseUrl,
    String httpReferer = 'https://dotdotdot.ai',
    String xTitle = 'DotDotDot AI',
    Map<String, String> defaultHeaders = const {},
  }) : super(
          id: 'openrouter',
          providerType: ProviderType.openrouter,
          baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
          apiKey: apiKey,
          defaultHeaders: {
            'HTTP-Referer': httpReferer,
            'X-Title': xTitle,
            ...defaultHeaders,
          },
          // OpenRouter video routes are rare; only attempt if model id is marked.
          videoModelIds: const {'sora', 'openai/sora'},
        );
}
