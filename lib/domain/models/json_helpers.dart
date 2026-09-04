/// Sentinel for [copyWith] so nullable fields can be explicitly cleared.
const Object unsetValue = Object();

DateTime? dateTimeFromJson(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.parse(value as String);
}

String? dateTimeToJson(DateTime? value) => value?.toIso8601String();

List<String> stringListFromJson(Object? value) {
  if (value == null) return const [];
  return (value as List<dynamic>).map((e) => e as String).toList();
}
