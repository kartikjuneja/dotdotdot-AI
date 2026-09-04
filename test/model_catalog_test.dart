import 'package:dotdotdot_ai/ai/catalog/model_catalog.dart';
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
  });
}
