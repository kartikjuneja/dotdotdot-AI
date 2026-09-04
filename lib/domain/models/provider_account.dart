import 'json_helpers.dart';

/// Supported BYOK provider kinds.
enum ProviderType {
  openai,
  gemini,
  openrouter;

  static ProviderType fromJson(String value) => ProviderType.values.byName(value);

  String toJson() => name;
}

/// Local provider account metadata. API keys live in the secure vault only.
class ProviderAccount {
  const ProviderAccount({
    required this.id,
    required this.providerType,
    required this.displayName,
    required this.keyVaultRef,
    required this.enabled,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final ProviderType providerType;
  final String displayName;

  /// Opaque ref into the secure key vault; never the raw secret.
  final String keyVaultRef;
  final bool enabled;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ProviderAccount copyWith({
    String? id,
    ProviderType? providerType,
    String? displayName,
    String? keyVaultRef,
    bool? enabled,
    DateTime? updatedAt,
    Object? deletedAt = unsetValue,
  }) {
    return ProviderAccount(
      id: id ?? this.id,
      providerType: providerType ?? this.providerType,
      displayName: displayName ?? this.displayName,
      keyVaultRef: keyVaultRef ?? this.keyVaultRef,
      enabled: enabled ?? this.enabled,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, unsetValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  factory ProviderAccount.fromJson(Map<String, dynamic> json) {
    return ProviderAccount(
      id: json['id'] as String,
      providerType: ProviderType.fromJson(json['providerType'] as String),
      displayName: json['displayName'] as String,
      keyVaultRef: json['keyVaultRef'] as String,
      enabled: json['enabled'] as bool? ?? true,
      updatedAt: dateTimeFromJson(json['updatedAt'])!,
      deletedAt: dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerType': providerType.toJson(),
        'displayName': displayName,
        'keyVaultRef': keyVaultRef,
        'enabled': enabled,
        'updatedAt': dateTimeToJson(updatedAt),
        'deletedAt': dateTimeToJson(deletedAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderAccount &&
          other.id == id &&
          other.providerType == providerType &&
          other.displayName == displayName &&
          other.keyVaultRef == keyVaultRef &&
          other.enabled == enabled &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        providerType,
        displayName,
        keyVaultRef,
        enabled,
        updatedAt,
        deletedAt,
      );
}
