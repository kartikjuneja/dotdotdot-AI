import 'json_helpers.dart';
import 'provider_account.dart';

/// Modalities a model may expose in the catalog / picker.
enum ModelCapability {
  chat,
  image,
  video,
  audio,
  embedding;

  static ModelCapability fromJson(String value) =>
      ModelCapability.values.byName(value);

  String toJson() => name;
}

/// Catalog entry describing a provider model and its capabilities.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.providerType,
    required this.name,
    required this.capabilities,
    required this.streaming,
    required this.experimental,
    this.notes,
  });

  final String id;
  final ProviderType providerType;
  final String name;
  final Set<ModelCapability> capabilities;
  final bool streaming;
  final bool experimental;
  final String? notes;

  ModelInfo copyWith({
    String? id,
    ProviderType? providerType,
    String? name,
    Set<ModelCapability>? capabilities,
    bool? streaming,
    bool? experimental,
    Object? notes = unsetValue,
  }) {
    return ModelInfo(
      id: id ?? this.id,
      providerType: providerType ?? this.providerType,
      name: name ?? this.name,
      capabilities: capabilities ?? this.capabilities,
      streaming: streaming ?? this.streaming,
      experimental: experimental ?? this.experimental,
      notes: identical(notes, unsetValue) ? this.notes : notes as String?,
    );
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    final caps = (json['capabilities'] as List<dynamic>? ?? const [])
        .map((e) => ModelCapability.fromJson(e as String))
        .toSet();
    return ModelInfo(
      id: json['id'] as String,
      providerType: ProviderType.fromJson(json['providerType'] as String),
      name: json['name'] as String,
      capabilities: caps,
      streaming: json['streaming'] as bool? ?? false,
      experimental: json['experimental'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerType': providerType.toJson(),
        'name': name,
        'capabilities':
            capabilities.map((c) => c.toJson()).toList(growable: false),
        'streaming': streaming,
        'experimental': experimental,
        'notes': notes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelInfo &&
          other.id == id &&
          other.providerType == providerType &&
          other.name == name &&
          other.capabilities.length == capabilities.length &&
          other.capabilities.containsAll(capabilities) &&
          other.streaming == streaming &&
          other.experimental == experimental &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        id,
        providerType,
        name,
        Object.hashAllUnordered(capabilities),
        streaming,
        experimental,
        notes,
      );
}
