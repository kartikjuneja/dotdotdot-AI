import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/model_info.dart';
import '../../domain/models/provider_account.dart';

/// Bundled model catalog with optional live-adapter merge.
class ModelCatalog {
  ModelCatalog({List<ModelInfo>? initial})
      : _models = List<ModelInfo>.from(initial ?? const []);

  static const String assetPath = 'assets/catalog/models.json';

  List<ModelInfo> _models;

  /// All known models (bundled + merged live).
  List<ModelInfo> all() => List<ModelInfo>.unmodifiable(_models);

  /// Models for a single [providerType].
  List<ModelInfo> byProvider(ProviderType providerType) => _models
      .where((m) => m.providerType == providerType)
      .toList(growable: false);

  /// Models that advertise [capability].
  List<ModelInfo> byCapability(ModelCapability capability) => _models
      .where((m) => m.capabilities.contains(capability))
      .toList(growable: false);

  /// Lookup by model id (first match).
  ModelInfo? find(String id) {
    for (final m in _models) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Loads [assetPath] and optionally merges [liveModels] (live wins on id+provider).
  Future<void> load({List<ModelInfo>? liveModels}) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('models.json must be a JSON array');
    }
    final bundled = decoded
        .cast<dynamic>()
        .map((e) => ModelInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    _models = merge(bundled, liveModels ?? const []);
  }

  /// Replaces the in-memory catalog after an explicit merge.
  void replaceAll(List<ModelInfo> models) {
    _models = List<ModelInfo>.from(models);
  }

  /// Merges [live] over [bundled]: same `(id, providerType)` is replaced by live.
  static List<ModelInfo> merge(
    List<ModelInfo> bundled,
    List<ModelInfo> live,
  ) {
    final byKey = <String, ModelInfo>{};
    for (final m in bundled) {
      byKey[_key(m)] = m;
    }
    for (final m in live) {
      byKey[_key(m)] = m;
    }
    return byKey.values.toList(growable: false);
  }

  static String _key(ModelInfo m) => '${m.providerType.name}:${m.id}';
}
