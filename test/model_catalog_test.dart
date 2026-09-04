import 'package:dotdotdot_ai/ai/catalog/model_catalog.dart';
import 'package:dotdotdot_ai/app/providers.dart';
import 'package:dotdotdot_ai/domain/models/model_info.dart';
import 'package:dotdotdot_ai/domain/models/provider_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelCatalog', () {
    test('load from asset populates models', () async {
      final catalog = ModelCatalog();
      await catalog.load();

      final all = catalog.all();
      expect(all, isNotEmpty);
      expect(catalog.find('gpt-4o'), isNotNull);
      expect(catalog.find('gpt-4o')!.capabilities, contains(ModelCapability.chat));
      expect(catalog.find('gemini-3.6-flash'), isNotNull);
      expect(catalog.find('gemini-2.0-flash'), isNull);
      expect(catalog.find('gpt-image-2'), isNotNull);
      expect(
        catalog.find('gemini-3.1-flash-image')!.capabilities,
        contains(ModelCapability.image),
      );
    });

    test('byCapability filters chat models', () async {
      final catalog = ModelCatalog();
      await catalog.load();

      final chat = catalog.byCapability(ModelCapability.chat);
      expect(chat, isNotEmpty);
      expect(
        chat.every((m) => m.capabilities.contains(ModelCapability.chat)),
        isTrue,
      );
    });

    test('byCapability filters image models', () async {
      final catalog = ModelCatalog();
      await catalog.load();

      final image = catalog.byCapability(ModelCapability.image);
      expect(image, isNotEmpty);
      expect(
        image.every((m) => m.capabilities.contains(ModelCapability.image)),
        isTrue,
      );
      expect(
        image.any((m) => m.id == 'dall-e-3'),
        isTrue,
      );
      expect(
        image.any((m) => m.id == 'gpt-image-2'),
        isTrue,
      );
      expect(
        image.any((m) => m.id == 'gemini-3.1-flash-image'),
        isTrue,
      );
    });

    test('byCapability returns empty for unused capability when absent', () async {
      final catalog = ModelCatalog(
        initial: const [
          ModelInfo(
            id: 'only-chat',
            providerType: ProviderType.openai,
            name: 'Only Chat',
            capabilities: {ModelCapability.chat},
            streaming: true,
            experimental: false,
          ),
        ],
      );

      expect(catalog.byCapability(ModelCapability.embedding), isEmpty);
      expect(catalog.byCapability(ModelCapability.chat), hasLength(1));
    });

    test('defaultChatModelId prefers models for enabled providers', () async {
      final catalog = ModelCatalog();
      await catalog.load();
      final id = defaultChatModelId(
        catalog,
        accounts: [
          ProviderAccount(
            id: 'g',
            providerType: ProviderType.gemini,
            displayName: 'Gemini',
            keyVaultRef: 'vault',
            enabled: true,
            updatedAt: DateTime.utc(2026, 9, 1),
          ),
        ],
      );
      expect(id, contains('gemini'));
    });
  });
}
