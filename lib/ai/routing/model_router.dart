import '../../domain/models/model_info.dart';
import '../../domain/models/provider_account.dart';

/// Picks an enabled provider account for a catalog model.
class ModelRouter {
  const ModelRouter._();

  /// Prefer an account whose [ProviderType] matches [model.providerType].
  static ProviderAccount? pickAccount(
    ModelInfo model,
    List<ProviderAccount> accounts,
  ) {
    final enabled =
        accounts.where((a) => a.enabled && !a.isDeleted).toList(growable: false);
    for (final a in enabled) {
      if (a.providerType == model.providerType) return a;
    }
    return enabled.isEmpty ? null : enabled.first;
  }

  /// Alias used by some call sites.
  static ProviderAccount? pick(
    ModelInfo model,
    List<ProviderAccount> accounts,
  ) =>
      pickAccount(model, accounts);
}
