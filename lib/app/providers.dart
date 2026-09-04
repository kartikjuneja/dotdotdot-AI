import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast.dart';

import '../ai/catalog/model_catalog.dart';
import '../ai/providers/ai_provider.dart';
import '../ai/providers/provider_factory.dart';
import '../ai/routing/model_router.dart';
import '../core/clock.dart';
import '../core/ids.dart';
import '../data/db/app_database.dart';
import '../data/db/sembast_chat_repository.dart';
import '../data/db/sembast_context_repository.dart';
import '../data/db/sembast_memory_repository.dart';
import '../data/db/sembast_message_repository.dart';
import '../data/db/sembast_plan_repository.dart';
import '../data/db/sembast_project_repository.dart';
import '../data/db/sembast_provider_repository.dart';
import '../data/secure/key_vault.dart';
import '../data/sync/drive_sync_service.dart';
import '../domain/models/chat.dart';
import '../domain/models/model_info.dart';
import '../domain/models/provider_account.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/context_repository.dart';
import '../domain/repositories/memory_repository.dart';
import '../domain/repositories/message_repository.dart';
import '../domain/repositories/plan_repository.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/repositories/provider_repository.dart';
import '../domain/services/context_merge_service.dart';
import '../domain/services/memory_service.dart';
import '../domain/services/plan_patch_service.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final uuidProvider = Provider<UuidV4>((ref) => UuidV4());

final databaseProvider = FutureProvider<Database>((ref) {
  return createAppDatabase();
});

final keyVaultProvider = Provider<KeyVault>((ref) => KeyVault());

final modelCatalogProvider = FutureProvider<ModelCatalog>((ref) async {
  final catalog = ModelCatalog();
  await catalog.load();
  return catalog;
});

final driveSyncServiceProvider = Provider<DriveSyncService>((ref) {
  final service = DriveSyncService(keyVault: ref.watch(keyVaultProvider));
  // Lazy-attach Database when ready (sync can wait for first open).
  ref.listen<AsyncValue<Database>>(
    databaseProvider,
    (_, next) {
      next.whenData((db) => service.attach(database: db));
    },
    fireImmediately: true,
  );
  ref.onDispose(service.dispose);
  return service;
});

final contextMergeServiceProvider =
    Provider<ContextMergeService>((ref) => const ContextMergeService());

final planPatchServiceProvider =
    Provider<PlanPatchService>((ref) => const PlanPatchService());

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastChatRepository(db);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastMessageRepository(db);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastProjectRepository(db);
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastPlanRepository(db);
});

final contextRepositoryProvider = Provider<ContextRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastContextRepository(db);
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastMemoryRepository(db);
});

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SembastProviderRepository(db);
});

final memoryServiceProvider = Provider<MemoryService>((ref) {
  return MemoryService(
    ref.watch(memoryRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(uuidProvider),
  );
});

final chatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  return ref.watch(chatRepositoryProvider).watchAll();
});

final projectsStreamProvider = StreamProvider((ref) {
  return ref.watch(projectRepositoryProvider).watchAll();
});

final providerAccountsStreamProvider = StreamProvider<List<ProviderAccount>>((
  ref,
) {
  return ref.watch(providerRepositoryProvider).watchAll();
});

final driveStatusProvider = StreamProvider((ref) {
  return ref.watch(driveSyncServiceProvider).watchStatus();
});

/// Resolves an [AiProvider] for a catalog model using an enabled account + vault key.
///
/// Accepts repositories (not [Ref]/[WidgetRef]) so both notifiers and widgets
/// can call this without a Riverpod type mismatch.
Future<AiProvider?> resolveAiProvider({
  required ModelCatalog catalog,
  required ProviderRepository providers,
  required KeyVault vault,
  required String modelId,
  String? preferredAccountId,
}) async {
  final model = catalog.find(modelId);
  final accounts = await providers.list();
  final enabled = accounts.where((a) => a.enabled && !a.isDeleted).toList();
  if (enabled.isEmpty) return null;

  ProviderAccount? account;
  if (preferredAccountId != null) {
    for (final a in enabled) {
      if (a.id == preferredAccountId) {
        account = a;
        break;
      }
    }
  }
  account ??= model != null
      ? ModelRouter.pickAccount(model, enabled)
      : enabled.first;
  if (account == null) return null;

  final key = await vault.readKey(account.keyVaultRef);
  if (key == null || key.trim().isEmpty) return null;
  return ProviderFactory.create(account, key);
}

String defaultChatModelId(ModelCatalog catalog) {
  final chatModels = catalog.byCapability(ModelCapability.chat);
  if (chatModels.isEmpty) return 'gpt-4o-mini';
  final preferred = chatModels.where((m) => m.id.contains('mini'));
  if (preferred.isNotEmpty) return preferred.first.id;
  return chatModels.first.id;
}

Future<Chat> createNewChat(
  WidgetRef ref, {
  String? projectId,
  String? planNodeId,
  String? title,
  String? modelId,
}) async {
  final clock = ref.read(clockProvider);
  final ids = ref.read(uuidProvider);
  final catalog = await ref.read(modelCatalogProvider.future);
  final now = clock.now();
  final chat = Chat(
    id: ids.next(),
    title: title ?? 'New chat',
    projectId: projectId,
    planNodeId: planNodeId,
    modelId: modelId ?? defaultChatModelId(catalog),
    createdAt: now,
    updatedAt: now,
  );
  return ref.read(chatRepositoryProvider).save(chat);
}

/// Navigates to a freshly created chat.
Future<void> openNewChat(
  BuildContext context,
  WidgetRef ref, {
  String? projectId,
  String? planNodeId,
}) async {
  final chat = await createNewChat(
    ref,
    projectId: projectId,
    planNodeId: planNodeId,
  );
  if (context.mounted) {
    context.go('/chat/${chat.id}');
  }
}
