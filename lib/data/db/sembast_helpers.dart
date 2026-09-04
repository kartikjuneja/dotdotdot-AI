import 'package:sembast/sembast.dart';

/// Shared helpers for Sembast record maps keyed by entity id.
Map<String, dynamic> mapFromRecord(
  RecordSnapshot<String, Map<String, Object?>> snap,
) {
  return Map<String, dynamic>.from(snap.value);
}

Map<String, Object?> mapForPut(Map<String, dynamic> json) {
  return Map<String, Object?>.from(json);
}

bool isNotSoftDeleted(Map<String, dynamic> json) => json['deletedAt'] == null;

Finder softDeleteAwareFinder({
  Filter? extra,
  bool includeDeleted = false,
  List<SortOrder>? sortOrders,
}) {
  Filter? filter = extra;
  if (!includeDeleted) {
    final active = Filter.isNull('deletedAt');
    filter = filter == null ? active : Filter.and([active, filter]);
  }
  return Finder(
    filter: filter,
    sortOrders: sortOrders,
  );
}
