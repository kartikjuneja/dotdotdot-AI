/// Scope kinds for memory and custom context documents.
enum ContextScopeKind {
  global,
  project,
  plan,
  chat;

  static ContextScopeKind fromJson(String value) =>
      ContextScopeKind.values.byName(value);

  String toJson() => name;
}
