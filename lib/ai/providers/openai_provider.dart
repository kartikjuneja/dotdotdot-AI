import '../../domain/models/provider_account.dart';
import 'openai_compatible_provider.dart';

/// First-party OpenAI API (`https://api.openai.com/v1`).
class OpenAiProvider extends OpenAiCompatibleProvider {
  OpenAiProvider({
    required String apiKey,
    String? baseUrl,
    Map<String, String> defaultHeaders = const {},
  }) : super(
          id: 'openai',
          providerType: ProviderType.openai,
          baseUrl: baseUrl ?? 'https://api.openai.com/v1',
          apiKey: apiKey,
          defaultHeaders: defaultHeaders,
          videoModelIds: const {'sora'},
        );
}
